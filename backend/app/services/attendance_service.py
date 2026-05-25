import os

import json

import logging

from dataclasses import dataclass

from datetime import datetime, timezone

from app.core.config import settings

from app.repositories.attendance_repo import AttendanceRepository

from app.repositories.session_repo import SessionRepository

from app.repositories.geofence_repo import GeofenceRepository

from app.repositories.student_repo import StudentRepository

from app.repositories.class_repo import ClassRepository

from app.services.ai_orchestrator import AIOrchestrator

from app.utils.geofencing import GPSCoordinate, calculate_haversine_distance

from app.db.redis import get_redis

from prisma.models import Attendance

from app.api.ws import manager

logger = logging.getLogger("app.attendance")

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

    async def mark_attendance(

        self, submission: AttendanceSubmission

    ) -> Attendance:

        session = None

        redis_client = None

        cache_key = f"session:{submission.session_id}"

        try:

            redis_client = get_redis()

            cached_data = await redis_client.get(cache_key)

            if cached_data:

                logger.info(f"⚡ Redis Cache Hit: {cache_key}")

                data = json.loads(cached_data)

                end_time_str = data["endTime"]

                if end_time_str.endswith("Z"):

                    end_time_str = end_time_str[:-1] + "+00:00"

                session = CachedSession(

                    id=data["id"],

                    is_active=data["isActive"],

                    academic_class_id=data["academicClassId"],

                    end_time=datetime.fromisoformat(end_time_str)

                )

        except Exception as cache_err:

            logger.warning(f"⚠️ Redis Session Cache read failed: {cache_err}. Falling back to DB.")

        if not session:

            session = await self.session_repo.get_by_id(submission.session_id)

            if not session or not session.isActive:

                raise ValueError("Attendance session is not active or not found.")

            if redis_client:

                try:

                    now = datetime.now(timezone.utc)

                    end_time = session.endTime

                    if end_time.tzinfo is None:

                        end_time = end_time.replace(tzinfo=timezone.utc)

                    remaining = int((end_time - now).total_seconds())

                    ttl = max(1, min(remaining, 600))

                    session_dict = {

                        "id": session.id,

                        "isActive": session.isActive,

                        "academicClassId": session.academicClassId,

                        "endTime": session.endTime.isoformat()

                    }

                    await redis_client.setex(

                        cache_key,

                        ttl,

                        json.dumps(session_dict)

                    )

                    logger.info(f"💾 Redis Cache Write: {cache_key} (TTL: {ttl}s)")

                except Exception as cache_err:

                    logger.warning(f"⚠️ Redis Session Cache write failed: {cache_err}")

        if not session.isActive:

            raise ValueError("Attendance session is not active or not found.")

        geofence = await self.geofence_repo.get_by_class_id(session.academicClassId)

        geofence_missing = False

        remarks = None

        if not geofence:

            logger.warning(

                f"Missing Geofence configuration for AcademicClass {session.academicClassId}. Student: {submission.student_id}"

            )

            geofence_missing = True

            remarks = "Missing Geofence Data"

        else:

            student_gps = GPSCoordinate(submission.latitude, submission.longitude)

            class_gps = GPSCoordinate(geofence.latitude, geofence.longitude)

            distance = calculate_haversine_distance(student_gps, class_gps)

            if distance > geofence.radiusMeters:
                outside_by = distance - geofence.radiusMeters
                raise ValueError(
                    f"Student is outside geofence boundary by {outside_by:.1f}m. "
                    f"(Distance: {distance:.1f}m, Allowed Radius: {geofence.radiusMeters:.1f}m)"
                )

        student = await self.student_repo.get_by_id(submission.student_id)

        if not student:

            raise ValueError("Student record not found.")

        face_embedding = await self.student_repo.get_face_embedding(submission.student_id)

        if not face_embedding:

            raise ValueError("Student face embedding is not registered.")

        ai_results = await self.ai_orchestrator.analyze_attendance(

            submission.image_path, face_embedding

        )

        face_score = ai_results["face_score"]

        liveness_score = ai_results["liveness_score"]

        bg_score = ai_results["background_score"]

        final_score = (

            (settings.FACE_WEIGHT * face_score)

            + (settings.LIVENESS_WEIGHT * liveness_score)

            + (settings.BACKGROUND_WEIGHT * bg_score)

        )

        if geofence_missing:

            status = "Flagged"

        else:

            status = "Present" if final_score >= settings.PASS_THRESHOLD else "Flagged"

        attendance_record = await self.attendance_repo.create(

            {

                "studentId": submission.student_id,

                "sessionId": submission.session_id,

                "status": status,

                "faceScore": face_score,

                "livenessScore": liveness_score,

                "backgroundScore": bg_score,

                "finalAiScore": final_score,

                "gpsLatitude": submission.latitude,

                "gpsLongitude": submission.longitude,

                "remarks": remarks,

            }

        )

        try:

            await manager.send_personal_message(

                {

                    "type": "attendance_updated",

                    "session_id": submission.session_id,

                    "status": status,

                },

                student_id=submission.student_id,

            )

            logger.info(f"📡 WebSocket broadcast sent to student {submission.student_id}")

        except Exception as ws_err:

            logger.warning(f"WebSocket broadcast failed: {ws_err}")

        try:

            from app.services.gamification_service import GamificationService

            gamification = GamificationService()

            streak_result = await gamification.update_streak(submission.student_id, status)

            logger.info(f"🔥 Streak update: {streak_result}")

        except Exception as streak_err:

            logger.warning(f"Streak update failed: {streak_err}")

        if status == "Present" and os.path.exists(submission.image_path):

            try:

                os.remove(submission.image_path)

                logger.info(

                    f"Successfully deleted temporary image {submission.image_path} for Student {submission.student_id}."

                )

            except Exception as err:

                logger.error(

                    f"Could not remove temporary image {submission.image_path}: {err}"

                )

        return attendance_record

    async def register_face(self, student_id: str, image_path: str) -> bool:

        embedding = await self.ai_orchestrator.extract_face_embedding(image_path)

        if not embedding:

            return False

        await self.student_repo.update_face_embedding(student_id, embedding)

        return True

    async def review_attendance(

        self, attendance_id: str, status: str, remarks: str

    ) -> bool:

        record = await self.attendance_repo.get_by_id(attendance_id)

        if not record or record.status != "Flagged":

            return False

        await self.attendance_repo.update_review(attendance_id, status, remarks)

        try:

            await manager.send_personal_message(

                {

                    "type": "attendance_updated",

                    "session_id": record.sessionId,

                    "status": status,

                },

                student_id=record.studentId,

            )

            logger.info(f"📡 WebSocket broadcast sent to student {record.studentId} after review update")

        except Exception as ws_err:

            logger.warning(f"WebSocket broadcast failed: {ws_err}")

        return True

