from datetime import datetime
from typing import List, Optional

from fastapi import HTTPException, status

from app.db.client import db
from app.repositories.teacher_repo import TeacherRepository
from app.repositories.class_repo import ClassRepository
from app.repositories.geofence_repo import GeofenceRepository
from app.schemas.teacher import (
    GeofenceUpsert, GeofenceResponse, AcademicClassWithGeofenceResponse,
    StudentRosterItem, SessionAttendanceResponse, ClassStatsResponse,
    SessionWithClassResponse, SessionTrendItem, BulkMarkRequest, AbsentStudentItem,
)


class TeacherService:
    def __init__(self) -> None:
        self.teacher_repo = TeacherRepository()
        self.class_repo = ClassRepository()
        self.geofence_repo = GeofenceRepository()

    async def get_teacher_by_user_id(self, user_id: str):
        teacher = await self.teacher_repo.get_by_user_id(user_id)
        if not teacher:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Teacher profile not found.")
        return teacher

    @staticmethod
    def _resolve_full_name(first: Optional[str], last: Optional[str]) -> str:
        return f"{first or ''} {last or ''}".strip() or "—"

    async def get_classes_by_teacher_user_id(self, user_id: str) -> List[AcademicClassWithGeofenceResponse]:
        teacher = await self.get_teacher_by_user_id(user_id)
        classes = await db.academicclass.find_many(
            where={"teacherId": teacher.id}, include={"geofence": True, "subject": True}
        )
        return [
            AcademicClassWithGeofenceResponse(
                id=c.id, name=c.name, subject=c.subject.name if c.subject else "—",
                teacherId=c.teacherId,
                geofence=GeofenceResponse.model_validate(c.geofence) if c.geofence else None,
            )
            for c in classes
        ]

    async def upsert_geofence(self, user_id: str, class_id: str, data: GeofenceUpsert) -> GeofenceResponse:
        teacher = await self.get_teacher_by_user_id(user_id)
        academic_class = await self.class_repo.get_by_id(class_id)
        if not academic_class:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Academic Class not found.")
        if academic_class.teacherId != teacher.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access Denied: You do not teach this academic class.")
        geofence = await self.geofence_repo.upsert_geofence(class_id=class_id, latitude=data.latitude, longitude=data.longitude, radius=data.radius_meters)
        return GeofenceResponse.model_validate(geofence)

    async def _get_session_with_auth(self, session_id: str, teacher_id: str):
        session = await db.session.find_unique(where={"id": session_id}, include={"academicClass": True})
        if not session:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Attendance Session not found.")
        if session.academicClass.teacherId != teacher_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access Denied: You do not teach this academic class.")
        return session

    async def get_session_attendance_roster(self, user_id: str, session_id: str) -> SessionAttendanceResponse:
        teacher = await self.get_teacher_by_user_id(user_id)
        session = await self._get_session_with_auth(session_id, teacher.id)

        enrollments = await db.enrollment.find_many(
            where={"academicClassId": session.academicClassId},
            include={"student": {"include": {"user": True}}},
        )
        attendance_map = {r.studentId: r for r in await db.attendance.find_many(where={"sessionId": session_id})}

        roster = [
            StudentRosterItem(
                student_id=s.id, enrollment_number=s.enrollmentNumber,
                full_name=self._resolve_full_name(s.firstName, s.lastName),
                email=s.user.email,
                status=(rec := attendance_map.get(s.id)).status if s.id in attendance_map else "Absent",
                final_score=rec.finalAiScore if s.id in attendance_map else 0.0,
                marked_at=rec.createdAt if s.id in attendance_map else None,
            )
            for e in enrollments if (s := e.student)
        ]
        return SessionAttendanceResponse(session_id=session_id, class_name=session.academicClass.name, roster=roster)

    async def get_absent_students(self, session_id: str, user_id: str) -> List[AbsentStudentItem]:
        teacher = await self.get_teacher_by_user_id(user_id)
        session = await self._get_session_with_auth(session_id, teacher.id)

        marked_ids = {r.studentId for r in await db.attendance.find_many(where={"sessionId": session_id})}
        enrollments = await db.enrollment.find_many(
            where={"academicClassId": session.academicClassId},
            include={"student": {"include": {"user": True}}},
        )
        return [
            AbsentStudentItem(
                student_id=s.id, enrollment_number=s.enrollmentNumber,
                full_name=self._resolve_full_name(s.firstName, s.lastName),
                email=s.user.email if s.user else "",
            )
            for e in enrollments if (s := e.student) and s.id not in marked_ids
        ]

    async def bulk_mark_attendance(self, session_id: str, user_id: str, request: BulkMarkRequest) -> int:
        teacher = await self.get_teacher_by_user_id(user_id)
        await self._get_session_with_auth(session_id, teacher.id)

        count = 0
        from app.services.gamification_service import GamificationService
        gamification_service = GamificationService()
        for record in request.records:
            await db.attendance.upsert(
                where={"studentId_sessionId": {"studentId": record.student_id, "sessionId": session_id}},
                data={
                    "create": {
                        "studentId": record.student_id, "sessionId": session_id, "status": record.status,
                        "faceScore": 0.0, "livenessScore": 0.0, "backgroundScore": 0.0, "finalAiScore": 0.0,
                        "gpsLatitude": 0.0, "gpsLongitude": 0.0, "remarks": "Manual entry by teacher",
                    },
                    "update": {"status": record.status, "remarks": "Manual entry by teacher"},
                },
            )
            count += 1
            try:
                await gamification_service.recalculate_student_streak(record.student_id)
            except Exception as e:
                from app.core.logging_config import get_logger
                get_logger("app.teacher").warning("Failed to recalculate streak for student %s in bulk mark: %s", record.student_id, e)
        return count

    async def export_class_attendance(self, class_id: str, user_id: str, from_date: Optional[datetime], to_date: Optional[datetime]) -> List[dict]:
        teacher = await self.get_teacher_by_user_id(user_id)
        academic_class = await self.class_repo.get_by_id(class_id)
        if not academic_class:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Academic Class not found.")
        if academic_class.teacherId != teacher.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access Denied: You do not teach this academic class.")

        session_where: dict = {"academicClassId": class_id}
        if from_date or to_date:
            time_filter = {}
            if from_date:
                time_filter["gte"] = from_date
            if to_date:
                time_filter["lte"] = to_date
            session_where["startTime"] = time_filter

        rows = []
        for s in await db.session.find_many(where=session_where, include={"academicClass": {"include": {"subject": True}}}, order={"startTime": "asc"}):
            for rec in await db.attendance.find_many(where={"sessionId": s.id}, include={"student": {"include": {"user": True}}}):
                stu = rec.student
                rows.append({
                    "enrollment_number": stu.enrollmentNumber if stu else "",
                    "first_name": stu.firstName or "" if stu else "",
                    "last_name": stu.lastName or "" if stu else "",
                    "email": stu.user.email if stu and stu.user else "",
                    "session_date": s.startTime.isoformat(),
                    "class_name": s.academicClass.name if s.academicClass else "—",
                    "subject": s.academicClass.subject.name if s.academicClass and s.academicClass.subject else "—",
                    "status": rec.status,
                    "final_ai_score": rec.finalAiScore,
                    "remarks": rec.remarks or "",
                })
        return rows

    async def get_class_stats(self, user_id: str, class_id: str) -> ClassStatsResponse:
        teacher = await self.get_teacher_by_user_id(user_id)
        academic_class = await self.class_repo.get_by_id(class_id)
        if not academic_class:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Academic Class not found.")
        if academic_class.teacherId != teacher.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access Denied.")

        total_students = await db.enrollment.count(where={"academicClassId": class_id})
        total_sessions = await db.session.count(where={"academicClassId": class_id})
        overall_percentage = 0.0
        history: List[SessionTrendItem] = []

        if total_students > 0 and total_sessions > 0:
            sessions = await db.session.find_many(where={"academicClassId": class_id}, order={"startTime": "asc"})
            session_ids = [s.id for s in sessions]

            present_count = await db.attendance.count(
                where={"sessionId": {"in": session_ids}, "status": {"in": ["Present", "Approved"]}}
            )
            overall_percentage = round((present_count / (total_students * total_sessions)) * 100.0, 2)

            for idx, s in enumerate(sessions):
                p_count = await db.attendance.count(
                    where={"sessionId": s.id, "status": {"in": ["Present", "Approved"]}}
                )
                history.append(SessionTrendItem(
                    session_id=s.id, session_name=f"Session {idx + 1}",
                    attendance_percentage=round((p_count / total_students) * 100.0, 2),
                ))

        return ClassStatsResponse(
            class_id=class_id, total_sessions=total_sessions, total_students=total_students,
            overall_attendance_percentage=overall_percentage, history=history,
        )

    async def manual_override_attendance(self, user_id: str, session_id: str, student_id: str, status_val: str) -> bool:
        teacher = await self.get_teacher_by_user_id(user_id)
        session = await self._get_session_with_auth(session_id, teacher.id)

        enrollment = await db.enrollment.find_unique(
            where={"studentId_academicClassId": {"studentId": student_id, "academicClassId": session.academicClassId}}
        )
        if not enrollment:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student is not enrolled in this class.")

        existing = await db.attendance.find_unique(
            where={"studentId_sessionId": {"studentId": student_id, "sessionId": session_id}}
        )
        if existing:
            await db.attendance.update(
                where={"id": existing.id},
                data={"status": status_val, "remarks": f"Manual override by Teacher to {status_val}"},
            )
        else:
            score = 1.0 if status_val == "Present" else 0.0
            await db.attendance.create(data={
                "studentId": student_id, "sessionId": session_id, "status": status_val,
                "faceScore": score, "livenessScore": score, "backgroundScore": score, "finalAiScore": score,
                "gpsLatitude": 0.0, "gpsLongitude": 0.0, "remarks": f"Manual override by Teacher to {status_val}",
            })

        try:
            from app.services.gamification_service import GamificationService
            await GamificationService().recalculate_student_streak(student_id)
        except Exception as e:
            from app.core.logging_config import get_logger
            get_logger("app.teacher").warning("Failed to recalculate streak for student %s in manual override: %s", student_id, e)

        return True

    async def get_teacher_sessions(self, user_id: str) -> List[SessionWithClassResponse]:
        teacher = await self.get_teacher_by_user_id(user_id)
        sessions = await db.session.find_many(
            where={"academicClass": {"teacherId": teacher.id}},
            include={"academicClass": {"include": {"subject": True}}},
            order={"endTime": "desc"},
        )
        
        from datetime import datetime, timezone
        now = datetime.now(timezone.utc)
        
        # Proactively deactivate expired sessions in DB
        expired_ids = [s.id for s in sessions if s.isActive and (s.endTime.replace(tzinfo=timezone.utc) if s.endTime.tzinfo is None else s.endTime) <= now]
        if expired_ids:
            from app.services.session_service import SessionService
            session_service = SessionService()
            for s_id in expired_ids:
                try:
                    await session_service.close_session(s_id)
                except Exception as e:
                    from app.core.logging_config import get_logger
                    get_logger("app.teacher").warning("Failed to close expired session %s: %s", s_id, e)

        return [
            SessionWithClassResponse(
                id=s.id, academicClassId=s.academicClassId, class_name=s.academicClass.name,
                subject=s.academicClass.subject.name if s.academicClass and s.academicClass.subject else "—",
                startTime=s.startTime, endTime=s.endTime,
                isActive=s.isActive and (s.endTime.replace(tzinfo=timezone.utc) if s.endTime.tzinfo is None else s.endTime) > now,
            )
            for s in sessions
        ]
