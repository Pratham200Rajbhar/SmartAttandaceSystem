import os
import json
from dataclasses import dataclass
from datetime import datetime, timezone

from prisma.models import Attendance

from app.core.config import settings
from app.core.logging_config import get_logger
from app.db.redis import get_redis
from app.repositories.attendance_repo import AttendanceRepository
from app.repositories.session_repo import SessionRepository
from app.repositories.geofence_repo import GeofenceRepository
from app.repositories.student_repo import StudentRepository
from app.repositories.class_repo import ClassRepository
from app.services.ai_orchestrator import AIOrchestrator
from app.utils.geofencing import GPSCoordinate, calculate_haversine_distance, GEOFENCE_GRACE_METERS
from app.api.ws import manager

logger = get_logger("app.attendance")


class CachedSession:
    def __init__(self, id: str, is_active: bool, academic_class_id: str, end_time: datetime):
        self.id = id
        self.isActive = is_active
        self.academicClassId = academic_class_id
        self.endTime = end_time


@dataclass(frozen=True)
class AttendanceSubmission:
    student_id: str
    session_id: str
    latitude: float
    longitude: float
    image_path: str


class AttendanceService:
    def __init__(self) -> None:
        self.attendance_repo = AttendanceRepository()
        self.session_repo = SessionRepository()
        self.geofence_repo = GeofenceRepository()
        self.student_repo = StudentRepository()
        self.class_repo = ClassRepository()
        self.ai_orchestrator = AIOrchestrator()

    async def mark_attendance(self, submission: AttendanceSubmission) -> Attendance:
        session = None
        redis_client = None
        cache_key = f"session:{submission.session_id}"

        try:
            redis_client = get_redis()
            cached = await redis_client.get(cache_key)
            if cached:
                data = json.loads(cached)
                end_time_str = data["endTime"].replace("Z", "+00:00")
                session = CachedSession(
                    id=data["id"], is_active=data["isActive"],
                    academic_class_id=data["academicClassId"],
                    end_time=datetime.fromisoformat(end_time_str),
                )
        except Exception:
            logger.warning("Redis session cache read failed. Falling back to DB.")

        if not session:
            session = await self.session_repo.get_by_id(submission.session_id)
            if not session or not session.isActive:
                raise ValueError("Attendance session is not active or not found.")

            if redis_client:
                try:
                    now = datetime.now(timezone.utc)
                    end = session.endTime.replace(tzinfo=timezone.utc) if session.endTime.tzinfo is None else session.endTime
                    ttl = max(1, min(int((end - now).total_seconds()), 600))
                    await redis_client.setex(cache_key, ttl, json.dumps({
                        "id": session.id, "isActive": session.isActive,
                        "academicClassId": session.academicClassId,
                        "endTime": session.endTime.isoformat(),
                    }))
                except Exception as e:
                    logger.warning("Redis session cache write failed: %s", e)

        if not session.isActive:
            raise ValueError("Attendance session is not active or not found.")

        geofence = await self.geofence_repo.get_by_class_id(session.academicClassId)
        geofence_missing = False
        remarks = None

        if not geofence:
            logger.warning("Missing geofence for class %s (student %s)", session.academicClassId, submission.student_id)
            geofence_missing = True
            remarks = "Missing Geofence Data"
        else:
            distance = calculate_haversine_distance(
                GPSCoordinate(submission.latitude, submission.longitude),
                GPSCoordinate(geofence.latitude, geofence.longitude),
            )
            if distance > geofence.radiusMeters + GEOFENCE_GRACE_METERS:
                effective_radius = geofence.radiusMeters + GEOFENCE_GRACE_METERS
                raise ValueError(
                    f"Student is outside geofence boundary by {distance - effective_radius:.1f}m. "
                    f"(Distance: {distance:.1f}m, Allowed Radius: {effective_radius:.1f}m)"
                )

        face_embedding = await self.student_repo.get_face_embedding(submission.student_id)
        if not face_embedding:
            raise ValueError("Student face embedding is not registered.")

        existing = await self.attendance_repo.get_by_student_and_session(submission.student_id, submission.session_id)
        if existing:
            raise ValueError("Attendance already submitted for this session.")

        ai_results = await self.ai_orchestrator.analyze_attendance(submission.image_path, face_embedding)
        final_score = (
            settings.FACE_WEIGHT * ai_results["face_score"]
            + settings.LIVENESS_WEIGHT * ai_results["liveness_score"]
            + settings.BACKGROUND_WEIGHT * ai_results["background_score"]
        )
        status = "Flagged" if geofence_missing else ("Present" if final_score >= settings.PASS_THRESHOLD else "Flagged")

        attendance_record = await self.attendance_repo.create({
            "studentId": submission.student_id, "sessionId": submission.session_id,
            "status": status,
            "faceScore": ai_results["face_score"], "livenessScore": ai_results["liveness_score"],
            "backgroundScore": ai_results["background_score"], "finalAiScore": final_score,
            "gpsLatitude": submission.latitude, "gpsLongitude": submission.longitude,
            "remarks": remarks,
        })

        try:
            msg = {"type": "attendance_updated", "session_id": submission.session_id, "status": status}
            await manager.send_personal_message(msg, student_id=submission.student_id)
            msg["student_id"] = submission.student_id
            await manager.broadcast_to_teachers(msg)
        except Exception as e:
            logger.warning("WebSocket broadcast failed: %s", e)

        if status == "Flagged":
            try:
                from app.services.notification_service import notify_student_attendance_flagged
                student = await self.student_repo.get_by_id(submission.student_id)
                if student and student.fcmToken:
                    ac = await self.class_repo.get_by_id(session.academicClassId)
                    class_name = ac.name if ac else "your class"
                    await notify_student_attendance_flagged(student.fcmToken, student.firstName or "Student", class_name)
            except Exception as e:
                logger.warning("FCM notification failed: %s", e)

        try:
            from app.services.gamification_service import GamificationService
            await GamificationService().update_streak(submission.student_id, status)
        except Exception as e:
            logger.warning("Streak update failed: %s", e)

        if status == "Present" and os.path.exists(submission.image_path):
            try:
                os.remove(submission.image_path)
            except Exception as e:
                logger.error("Failed to remove temp image %s: %s", submission.image_path, e, exc_info=True)

        return attendance_record

    async def register_face(self, student_id: str, image_path: str) -> bool:
        embedding = await self.ai_orchestrator.extract_face_embedding(image_path)
        if not embedding:
            return False
        await self.student_repo.update_face_embedding(student_id, embedding)
        return True

    async def review_attendance(self, attendance_id: str, status: str, remarks: str) -> bool:
        record = await self.attendance_repo.get_by_id(attendance_id)
        if not record or record.status != "Flagged":
            return False

        await self.attendance_repo.update_review(attendance_id, status, remarks)

        try:
            msg = {"type": "attendance_updated", "session_id": record.sessionId, "status": status}
            await manager.send_personal_message(msg, student_id=record.studentId)
            msg["student_id"] = record.studentId
            await manager.broadcast_to_teachers(msg)
        except Exception as e:
            logger.warning("WebSocket broadcast failed: %s", e)

        try:
            from app.services.notification_service import notify_student_attendance_reviewed
            student = await self.student_repo.get_by_id(record.studentId)
            if student and student.fcmToken:
                ac = await self.class_repo.get_by_id(record.session.academicClassId if record.session else "")
                class_name = ac.name if ac else "your class"
                await notify_student_attendance_reviewed(student.fcmToken, status, class_name)
        except Exception as e:
            logger.warning("FCM notification failed: %s", e)

        return True
