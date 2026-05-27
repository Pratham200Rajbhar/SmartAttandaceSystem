from prisma.models import SystemConfiguration
from app.db.client import db


class SystemConfigRepository:
    async def get_config(self) -> SystemConfiguration:
        """
        Gets the system configuration. If it doesn't exist, creates a default one.
        """
        config = await db.systemconfiguration.find_first()
        if not config:
            config = await db.systemconfiguration.create(
                data={
                    "isFaceRecognitionEnabled": True,
                    "isGpsVerificationEnabled": True,
                    "isAiBackgroundValidationEnabled": True,
                }
            )
        return config

    async def update_config(
        self,
        is_face_recognition_enabled: bool | None = None,
        is_gps_verification_enabled: bool | None = None,
        is_ai_background_validation_enabled: bool | None = None,
    ) -> SystemConfiguration:
        config = await self.get_config()
        
        update_data = {}
        if is_face_recognition_enabled is not None:
            update_data["isFaceRecognitionEnabled"] = is_face_recognition_enabled
        if is_gps_verification_enabled is not None:
            update_data["isGpsVerificationEnabled"] = is_gps_verification_enabled
        if is_ai_background_validation_enabled is not None:
            update_data["isAiBackgroundValidationEnabled"] = is_ai_background_validation_enabled
            
        return await db.systemconfiguration.update(
            where={"id": config.id},
            data=update_data,
        )
