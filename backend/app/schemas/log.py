from pydantic import BaseModel, Field, field_validator
from typing import Optional, Dict, Any
from datetime import datetime

_VALID_SOURCES = {"frontend", "mobile"}
_VALID_LEVELS = {"DEBUG", "INFO", "WARN", "WARNING", "ERROR", "CRITICAL"}


class LogEvent(BaseModel):
    """Structured log event ingested from frontend or mobile clients."""

    source: str = Field(..., description="Origin of the log event: 'frontend' or 'mobile'")
    level: str = Field(default="INFO", description="Severity: DEBUG, INFO, WARN, ERROR, CRITICAL")
    message: str = Field(..., min_length=1, description="The human-readable log message")
    timestamp: Optional[str] = Field(
        default=None,
        description="ISO-8601 UTC timestamp of the event. Defaults to server receive time.",
    )
    context: Optional[Dict[str, Any]] = Field(
        default=None,
        description="Optional structured metadata (e.g. screen name, component, error details)",
    )
    user_id: Optional[str] = Field(
        default=None,
        description="Authenticated user ID at the time of the event, if available",
    )
    platform_version: Optional[str] = Field(
        default=None,
        description="Client platform version (e.g. app version or browser UA string)",
    )

    @field_validator("source")
    @classmethod
    def validate_source(cls, value: str) -> str:
        """Reject log events from unknown sources."""
        if value.lower() not in _VALID_SOURCES:
            raise ValueError(
                f"Invalid log source '{value}'. Must be one of: {sorted(_VALID_SOURCES)}"
            )
        return value.lower()

    @field_validator("level")
    @classmethod
    def validate_level(cls, value: str) -> str:
        """Normalize and validate the log level."""
        normalized = value.upper()
        if normalized not in _VALID_LEVELS:
            return "INFO"
        return normalized

    @field_validator("timestamp", mode="before")
    @classmethod
    def set_default_timestamp(cls, value: Optional[str]) -> str:
        """Use the server receive time if the client did not supply a timestamp."""
        if value is None:
            return datetime.utcnow().isoformat() + "Z"
        return value
