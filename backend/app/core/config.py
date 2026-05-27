from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )

    PROJECT_NAME: str = "Smart Attendance System API"
    API_V1_STR: str = "/api/v1"
    DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5432/smart_attendance"
    JWT_SECRET: str = Field(default="", description="JWT signing secret (must be set via JWT_SECRET env var)")

    @field_validator("JWT_SECRET")
    @classmethod
    def jwt_secret_must_be_set(cls, v: str) -> str:
        if not v:
            raise ValueError(
                "JWT_SECRET environment variable is required. "
                "Set it in your .env file for security."
            )
        return v

    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440
    REDIS_URL: str = "redis://localhost:6379/0"
    UPLOAD_DIR: str = "static"
    FACE_WEIGHT: float = 0.50
    LIVENESS_WEIGHT: float = 0.30
    BACKGROUND_WEIGHT: float = 0.20
    PASS_THRESHOLD: float = 0.75
    FRONTEND_URL: str = Field(default="http://localhost:3000", description="Frontend URL for CORS")
    ENVIRONMENT: str = "development"
    LOG_LEVEL: str = Field(default="DEBUG", description="Logging level: DEBUG, INFO, WARNING, ERROR, CRITICAL")


settings = Settings()

