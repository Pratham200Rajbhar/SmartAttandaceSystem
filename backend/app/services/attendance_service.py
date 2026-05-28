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
from app.services.system_config_service import SystemConfigService
from app.utils.geofencing import GPSCoordinate, calculate_haversine_distance, is_within_geofence
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
    accuracy: float
    image_path: str | None = None


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
            if not session:
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

        now = datetime.now(timezone.utc)
        session_end = session.endTime.replace(tzinfo=timezone.utc) if session.endTime.tzinfo is None else session.endTime
        if not session.isActive or session_end <= now:
            if session.isActive:
                await self.session_repo.deactivate(session.id)
                try:
                    await get_redis().delete(f"session:{session.id}")
                except Exception:
                    pass
            raise ValueError("Attendance session is not active or not found.")

        config = await SystemConfigService().get_config()

        geofence_missing = False
        remarks = None

        if config.isGpsVerificationEnabled:
            geofence = await self.geofence_repo.get_by_class_id(session.academicClassId)
            if not geofence:
                logger.warning("Missing geofence for class %s (student %s)", session.academicClassId, submission.student_id)
                geofence_missing = True
                remarks = "Missing Geofence Data"
            else:
                student_coord = GPSCoordinate(submission.latitude, submission.longitude)
                classroom_coord = GPSCoordinate(geofence.latitude, geofence.longitude)
                is_inside = is_within_geofence(
                    student_coord=student_coord,
                    classroom_coord=classroom_coord,
                    base_radius=geofence.radiusMeters,
                    student_accuracy=submission.accuracy,
                )
                if not is_inside:
                    distance = calculate_haversine_distance(student_coord, classroom_coord)
                    effective_radius = geofence.radiusMeters + submission.accuracy
                    raise ValueError(
                        f"Student is outside geofence boundary by {distance - effective_radius:.1f}m. "
                        f"(Distance: {distance:.1f}m, Effective Allowed Radius: {effective_radius:.1f}m)"
                    )

        if config.isFaceRecognitionEnabled:
            face_embedding = await self.student_repo.get_face_embedding(submission.student_id)
            if not face_embedding:
                raise ValueError("Student face embedding is not registered.")
        else:
            face_embedding = []

        existing = await self.attendance_repo.get_by_student_and_session(submission.student_id, submission.session_id)
        if existing:
            raise ValueError("Attendance already submitted for this session.")

        if config.isFaceRecognitionEnabled or config.isAiBackgroundValidationEnabled:
            if not submission.image_path:
                raise ValueError("Image is required when verification is enabled.")
            ai_results = await self.ai_orchestrator.analyze_attendance(submission.image_path, face_embedding)
        else:
            ai_results = {"face_score": 1.0, "liveness_score": 1.0, "background_score": 1.0}
            
        if not config.isFaceRecognitionEnabled:
            ai_results["face_score"] = 1.0
            ai_results["liveness_score"] = 1.0
            
        if not config.isAiBackgroundValidationEnabled:
            ai_results["background_score"] = 1.0
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
                    await notify_student_attendance_flagged(student.fcmToken, student.firstName or "Student", class_name, attendance_record.id)
            except Exception as e:
                logger.warning("FCM notification failed: %s", e)

        try:
            from app.services.gamification_service import GamificationService
            await GamificationService().update_streak(submission.student_id, status)
        except Exception as e:
            logger.warning("Streak update failed: %s", e)

        if status == "Present" and submission.image_path and os.path.exists(submission.image_path):
            try:
                os.remove(submission.image_path)
            except Exception as e:
                logger.error("Failed to remove temp image %s: %s", submission.image_path, e, exc_info=True)

        return attendance_record

    async def analyze_attendance(self, submission: AttendanceSubmission) -> dict:
        """Run all validation + AI scoring but do NOT save the record.

        Returns a dict with scores, predicted status, and a short-lived
        review_token that can be passed to mark_attendance to skip re-running AI.
        """
        from datetime import timedelta
        from app.core.security import create_access_token

        # ── Session validation ──────────────────────────────────────────────
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
            if not session:
                raise ValueError("Attendance session is not active or not found.")

        now = datetime.now(timezone.utc)
        session_end = session.endTime.replace(tzinfo=timezone.utc) if session.endTime.tzinfo is None else session.endTime
        if not session.isActive or session_end <= now:
            if session.isActive:
                await self.session_repo.deactivate(session.id)
                try:
                    await get_redis().delete(f"session:{session.id}")
                except Exception:
                    pass
            raise ValueError("Attendance session is not active or not found.")

        config = await SystemConfigService().get_config()

        # ── Geofence check ──────────────────────────────────────────────────
        geofence_missing = False
        if config.isGpsVerificationEnabled:
            geofence = await self.geofence_repo.get_by_class_id(session.academicClassId)
            if not geofence:
                logger.warning("Missing geofence for class %s (student %s)", session.academicClassId, submission.student_id)
                geofence_missing = True
            else:
                student_coord = GPSCoordinate(submission.latitude, submission.longitude)
                classroom_coord = GPSCoordinate(geofence.latitude, geofence.longitude)
                is_inside = is_within_geofence(
                    student_coord=student_coord,
                    classroom_coord=classroom_coord,
                    base_radius=geofence.radiusMeters,
                    student_accuracy=submission.accuracy,
                )
                if not is_inside:
                    distance = calculate_haversine_distance(student_coord, classroom_coord)
                    effective_radius = geofence.radiusMeters + submission.accuracy
                    raise ValueError(
                        f"Student is outside geofence boundary by {distance - effective_radius:.1f}m. "
                        f"(Distance: {distance:.1f}m, Effective Allowed Radius: {effective_radius:.1f}m)"
                    )

        # ── Face embedding ──────────────────────────────────────────────────
        if config.isFaceRecognitionEnabled:
            face_embedding = await self.student_repo.get_face_embedding(submission.student_id)
            if not face_embedding:
                raise ValueError("Student face embedding is not registered.")
        else:
            face_embedding = []

        # ── Duplicate check ─────────────────────────────────────────────────
        existing = await self.attendance_repo.get_by_student_and_session(submission.student_id, submission.session_id)
        if existing:
            raise ValueError("Attendance already submitted for this session.")

        # ── AI scoring ──────────────────────────────────────────────────────
        if config.isFaceRecognitionEnabled or config.isAiBackgroundValidationEnabled:
            if not submission.image_path:
                raise ValueError("Image is required when verification is enabled.")
            ai_results = await self.ai_orchestrator.analyze_attendance(submission.image_path, face_embedding)
        else:
            ai_results = {"face_score": 1.0, "liveness_score": 1.0, "background_score": 1.0}
            
        if not config.isFaceRecognitionEnabled:
            ai_results["face_score"] = 1.0
            ai_results["liveness_score"] = 1.0
            
        if not config.isAiBackgroundValidationEnabled:
            ai_results["background_score"] = 1.0
        final_score = (
            settings.FACE_WEIGHT * ai_results["face_score"]
            + settings.LIVENESS_WEIGHT * ai_results["liveness_score"]
            + settings.BACKGROUND_WEIGHT * ai_results["background_score"]
        )
        predicted_status = "Flagged" if geofence_missing else ("Present" if final_score >= settings.PASS_THRESHOLD else "Flagged")

        # ── Build review token (5-minute TTL) ───────────────────────────────
        review_token = create_access_token(
            subject=submission.student_id,
            role="STUDENT",
            expires_delta=timedelta(minutes=5),
            extra_data={
                "type": "attendance_review",
                "session_id": submission.session_id,
                "face_score": ai_results["face_score"],
                "liveness_score": ai_results["liveness_score"],
                "background_score": ai_results["background_score"],
                "final_ai_score": final_score,
                "predicted_status": predicted_status,
                "geofence_missing": geofence_missing,
                "image_path": submission.image_path,
                "latitude": submission.latitude,
                "longitude": submission.longitude,
            },
        )

        return {
            "face_score": ai_results["face_score"],
            "liveness_score": ai_results["liveness_score"],
            "background_score": ai_results["background_score"],
            "final_ai_score": final_score,
            "predicted_status": predicted_status,
            "review_token": review_token,
        }

    async def confirm_attendance(self, student_id: str, review_token: str) -> "Attendance":
        """Confirm a previously analyzed submission using its review token.

        Decodes the token, validates it, and saves the attendance record
        without re-running AI inference.
        """
        from app.core.security import decode_access_token

        payload = decode_access_token(review_token)
        if not payload or payload.get("type") != "attendance_review":
            raise ValueError("Invalid or expired review token.")
        if payload.get("sub") != student_id:
            raise ValueError("Review token does not belong to this student.")

        session_id = payload["session_id"]

        # Re-check duplicate (student might have confirmed twice)
        existing = await self.attendance_repo.get_by_student_and_session(student_id, session_id)
        if existing:
            raise ValueError("Attendance already submitted for this session.")

        # Re-check session still active
        session = await self.session_repo.get_by_id(session_id)
        if not session:
            raise ValueError("Attendance session is no longer active.")

        now = datetime.now(timezone.utc)
        session_end = session.endTime.replace(tzinfo=timezone.utc) if session.endTime.tzinfo is None else session.endTime
        if not session.isActive or session_end <= now:
            if session.isActive:
                await self.session_repo.deactivate(session.id)
                try:
                    await get_redis().delete(f"session:{session.id}")
                except Exception:
                    pass
            raise ValueError("Attendance session is no longer active.")

        face_score = payload["face_score"]
        liveness_score = payload["liveness_score"]
        background_score = payload["background_score"]
        final_score = payload["final_ai_score"]
        predicted_status = payload["predicted_status"]
        geofence_missing = payload.get("geofence_missing", False)
        image_path = payload["image_path"]
        latitude = payload["latitude"]
        longitude = payload["longitude"]
        remarks = "Missing Geofence Data" if geofence_missing else None

        attendance_record = await self.attendance_repo.create({
            "studentId": student_id,
            "sessionId": session_id,
            "status": predicted_status,
            "faceScore": face_score,
            "livenessScore": liveness_score,
            "backgroundScore": background_score,
            "finalAiScore": final_score,
            "gpsLatitude": latitude,
            "gpsLongitude": longitude,
            "remarks": remarks,
        })

        try:
            msg = {"type": "attendance_updated", "session_id": session_id, "status": predicted_status}
            await manager.send_personal_message(msg, student_id=student_id)
            msg["student_id"] = student_id
            await manager.broadcast_to_teachers(msg)
        except Exception as e:
            logger.warning("WebSocket broadcast failed: %s", e)

        if predicted_status == "Flagged":
            try:
                from app.services.notification_service import notify_student_attendance_flagged
                student = await self.student_repo.get_by_id(student_id)
                if student and student.fcmToken:
                    ac = await self.class_repo.get_by_id(session.academicClassId)
                    class_name = ac.name if ac else "your class"
                    await notify_student_attendance_flagged(student.fcmToken, student.firstName or "Student", class_name, attendance_record.id)
            except Exception as e:
                logger.warning("FCM notification failed: %s", e)

        try:
            from app.services.gamification_service import GamificationService
            await GamificationService().update_streak(student_id, predicted_status)
        except Exception as e:
            logger.warning("Streak update failed: %s", e)

        if predicted_status == "Present" and image_path and os.path.exists(image_path):
            try:
                os.remove(image_path)
            except Exception as e:
                logger.error("Failed to remove temp image %s: %s", image_path, e, exc_info=True)

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

        try:
            from app.services.gamification_service import GamificationService
            await GamificationService().recalculate_student_streak(record.studentId)
        except Exception as e:
            logger.warning("Failed to recalculate streak for student %s: %s", record.studentId, e)

        return True
