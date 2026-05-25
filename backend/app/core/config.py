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

    JWT_SECRET: str = "supersecretkeychangeinproduction"

    JWT_ALGORITHM: str = "HS256"

    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440

    REDIS_URL: str = "redis://localhost:6379/0"

    UPLOAD_DIR: str = "uploads"

    FACE_WEIGHT: float = 0.50

    LIVENESS_WEIGHT: float = 0.30

    BACKGROUND_WEIGHT: float = 0.20

    PASS_THRESHOLD: float = 0.75

    ENVIRONMENT: str = "development"

settings = Settings()

