from datetime import datetime, timedelta, timezone
from typing import Optional

from app.core.logging_config import get_logger
from app.db.redis import get_redis
from app.repositories.session_repo import SessionRepository
from app.repositories.class_repo import ClassRepository
from app.schemas.teacher import SessionResponse, SessionStart

logger = get_logger("app.session")


class SessionService:
    def __init__(self) -> None:
        self.session_repo = SessionRepository()
        self.class_repo = ClassRepository()

    async def start_session(self, data: SessionStart, teacher_id: str) -> Optional[SessionResponse]:
        subject_class = await self.class_repo.get_by_id(data.academic_class_id)
        if not subject_class or subject_class.teacherId != teacher_id:
            return None

        active = await self.session_repo.get_active_session_by_class(data.academic_class_id)
        if active:
            await self.close_session(active.id)

        now = datetime.now(timezone.utc)
        session = await self.session_repo.create(
            class_id=data.academic_class_id, start_time=now, end_time=now + timedelta(minutes=data.duration_minutes)
        )
        return SessionResponse.model_validate(session)

    async def stop_session(self, session_id: str, teacher_id: str) -> bool:
        session = await self.session_repo.get_by_id(session_id)
        if not session or not session.isActive:
            return False

        subject_class = await self.class_repo.get_by_id(session.academicClassId)
        if not subject_class or subject_class.teacherId != teacher_id:
            return False

        await self.close_session(session_id)
        return True

    async def close_session(self, session_id: str) -> None:
        """Mark session as inactive, delete from Redis, and mark all unsubmitted students as Absent or Excused."""
        session = await self.session_repo.get_by_id(session_id)
        if not session or not session.isActive:
            return

        # 1. Deactivate in DB
        await self.session_repo.deactivate(session_id)

        # 2. Delete from Redis
        try:
            await get_redis().delete(f"session:{session_id}")
        except Exception as e:
            logger.warning("Failed to delete session from Redis: %s", e)

        # 3. Get enrollments and existing attendance
        from app.db.client import db
        from app.services.gamification_service import GamificationService
        
        enrollments = await db.enrollment.find_many(
            where={"academicClassId": session.academicClassId},
            include={"student": {"include": {"leaveRequests": True}}}
        )
        
        attendance_records = await db.attendance.find_many(where={"sessionId": session_id})
        submitted_student_ids = {a.studentId for a in attendance_records}

        gamification_service = GamificationService()
        sess_start = session.startTime.replace(tzinfo=timezone.utc) if session.startTime.tzinfo is None else session.startTime

        for enrollment in enrollments:
            student = enrollment.student
            if not student or student.id in submitted_student_ids:
                continue

            # Check if student was on approved leave during the session
            on_leave = False
            for leave in student.leaveRequests:
                if leave.status == "APPROVED":
                    l_start = leave.startDate.replace(tzinfo=timezone.utc) if leave.startDate.tzinfo is None else leave.startDate
                    l_end = leave.endDate.replace(tzinfo=timezone.utc) if leave.endDate.tzinfo is None else leave.endDate
                    if l_start <= sess_start <= l_end:
                        on_leave = True
                        break

            # Create the record
            status_val = "Excused" if on_leave else "Absent"
            remarks_val = "Excused via approved leave request" if on_leave else "Session ended without student submission"
            
            try:
                await db.attendance.create(data={
                    "studentId": student.id,
                    "sessionId": session_id,
                    "status": status_val,
                    "faceScore": 0.0,
                    "livenessScore": 0.0,
                    "backgroundScore": 0.0,
                    "finalAiScore": 0.0,
                    "gpsLatitude": 0.0,
                    "gpsLongitude": 0.0,
                    "remarks": remarks_val,
                })
            except Exception as e:
                logger.warning("Failed to create default attendance for student %s: %s", student.id, e)
                continue

            # Recalculate streak
            try:
                await gamification_service.recalculate_student_streak(student.id)
            except Exception as e:
                logger.warning("Failed to recalculate streak for student %s: %s", student.id, e)
