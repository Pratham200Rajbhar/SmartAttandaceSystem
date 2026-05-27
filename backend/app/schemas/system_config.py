from pydantic import BaseModel, Field


class SystemConfigResponse(BaseModel):
    is_face_recognition_enabled: bool = Field(..., alias="isFaceRecognitionEnabled")
    is_gps_verification_enabled: bool = Field(..., alias="isGpsVerificationEnabled")
    is_ai_background_validation_enabled: bool = Field(..., alias="isAiBackgroundValidationEnabled")

    class Config:
        populate_by_name = True


class SystemConfigUpdate(BaseModel):
    is_face_recognition_enabled: bool | None = Field(None, alias="isFaceRecognitionEnabled")
    is_gps_verification_enabled: bool | None = Field(None, alias="isGpsVerificationEnabled")
    is_ai_background_validation_enabled: bool | None = Field(None, alias="isAiBackgroundValidationEnabled")
