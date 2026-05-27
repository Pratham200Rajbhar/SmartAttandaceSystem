from typing import Optional, Dict, Any
from datetime import datetime, timezone

from pydantic import BaseModel, Field, field_validator

_VALID_SOURCES = {"frontend", "mobile"}
_VALID_LEVELS = {"DEBUG", "INFO", "WARN", "WARNING", "ERROR", "CRITICAL"}


class LogEvent(BaseModel):
    source: str = Field(..., description="Origin of the log event: 'frontend' or 'mobile'")
    level: str = Field(default="INFO", description="Severity: DEBUG, INFO, WARN, ERROR, CRITICAL")
    message: str = Field(..., min_length=1, description="The human-readable log message")
    timestamp: Optional[str] = Field(default=None, description="ISO-8601 UTC timestamp of the event")
    context: Optional[Dict[str, Any]] = Field(default=None, description="Optional structured metadata")
    user_id: Optional[str] = Field(default=None, description="Authenticated user ID at the time of the event")
    platform_version: Optional[str] = Field(default=None, description="Client platform version")

    @field_validator("source")
    @classmethod
    def validate_source(cls, value: str) -> str:
        if value.lower() not in _VALID_SOURCES:
            raise ValueError(f"Invalid log source '{value}'. Must be one of: {sorted(_VALID_SOURCES)}")
        return value.lower()

    @field_validator("level")
    @classmethod
    def validate_level(cls, value: str) -> str:
        normalized = value.upper()
        return normalized if normalized in _VALID_LEVELS else "INFO"

    @field_validator("timestamp", mode="before")
    @classmethod
    def set_default_timestamp(cls, value: Optional[str]) -> str:
        return value if value is not None else datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
