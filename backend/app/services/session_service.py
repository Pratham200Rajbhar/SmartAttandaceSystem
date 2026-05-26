from datetime import datetime, timedelta
from typing import Optional
from app.core.logging_config import get_logger

from app.repositories.session_repo import SessionRepository

from app.repositories.class_repo import ClassRepository

from app.schemas.teacher import SessionResponse, SessionStart

from app.db.redis import get_redis

logger = get_logger("app.session")

class SessionService:

    def __init__(self) -> None:

        self.session_repo = SessionRepository()

        self.class_repo = ClassRepository()

    async def start_session(

        self, data: SessionStart, teacher_id: str

    ) -> Optional[SessionResponse]:

        subject_class = await self.class_repo.get_by_id(data.academic_class_id)

        if not subject_class or subject_class.teacherId != teacher_id:

            return None

        active = await self.session_repo.get_active_session_by_class(

            data.academic_class_id

        )

        if active:

            await self.session_repo.deactivate(active.id)

            try:

                redis_client = get_redis()

                await redis_client.delete(f"session:{active.id}")

            except Exception as cache_err:

                pass

        now = datetime.utcnow()

        end = now + timedelta(minutes=data.duration_minutes)

        session = await self.session_repo.create(

            class_id=data.academic_class_id,

            start_time=now,

            end_time=end

        )

        return SessionResponse.model_validate(session)

    async def stop_session(

        self, session_id: str, teacher_id: str

    ) -> bool:

        session = await self.session_repo.get_by_id(session_id)

        if not session or not session.isActive:

            return False

        subject_class = await self.class_repo.get_by_id(session.academicClassId)

        if not subject_class or subject_class.teacherId != teacher_id:

            return False

        await self.session_repo.deactivate(session_id)

        try:

            redis_client = get_redis()

            await redis_client.delete(f"session:{session_id}")

        except Exception:

            pass

        return True

