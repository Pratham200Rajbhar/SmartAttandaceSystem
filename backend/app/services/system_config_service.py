import json
from prisma.models import SystemConfiguration
from app.repositories.system_config_repo import SystemConfigRepository
from app.db.redis import get_redis
from app.core.logging_config import get_logger

logger = get_logger("app.system_config")

CACHE_KEY = "system:config"


class SystemConfigService:
    def __init__(self) -> None:
        self.repo = SystemConfigRepository()

    async def get_config(self) -> SystemConfiguration:
        try:
            redis_client = get_redis()
            cached = await redis_client.get(CACHE_KEY)
            if cached:
                data = json.loads(cached)
                return SystemConfiguration(
                    id=data.get("id", ""),
                    isFaceRecognitionEnabled=data["isFaceRecognitionEnabled"],
                    isGpsVerificationEnabled=data["isGpsVerificationEnabled"],
                    isAiBackgroundValidationEnabled=data["isAiBackgroundValidationEnabled"],
                )
        except Exception:
            logger.warning("Redis config cache read failed. Falling back to DB.")

        config = await self.repo.get_config()

        try:
            redis_client = get_redis()
            await redis_client.set(
                CACHE_KEY,
                json.dumps({
                    "id": config.id,
                    "isFaceRecognitionEnabled": config.isFaceRecognitionEnabled,
                    "isGpsVerificationEnabled": config.isGpsVerificationEnabled,
                    "isAiBackgroundValidationEnabled": config.isAiBackgroundValidationEnabled,
                })
            )
        except Exception as e:
            logger.warning("Redis config cache write failed: %s", e)

        return config

    async def update_config(
        self,
        is_face_recognition_enabled: bool | None = None,
        is_gps_verification_enabled: bool | None = None,
        is_ai_background_validation_enabled: bool | None = None,
    ) -> SystemConfiguration:
        config = await self.repo.update_config(
            is_face_recognition_enabled=is_face_recognition_enabled,
            is_gps_verification_enabled=is_gps_verification_enabled,
            is_ai_background_validation_enabled=is_ai_background_validation_enabled,
        )

        try:
            redis_client = get_redis()
            await redis_client.set(
                CACHE_KEY,
                json.dumps({
                    "id": config.id,
                    "isFaceRecognitionEnabled": config.isFaceRecognitionEnabled,
                    "isGpsVerificationEnabled": config.isGpsVerificationEnabled,
                    "isAiBackgroundValidationEnabled": config.isAiBackgroundValidationEnabled,
                })
            )
        except Exception as e:
            logger.warning("Redis config cache write failed: %s", e)

        return config
