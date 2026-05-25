from pydantic import BaseModel, Field

from typing import Optional, Dict, Any

from datetime import datetime

class LogEvent(BaseModel):

    source: str = Field(..., description="The source of the log: 'frontend' or 'mobile'")

    level: str = Field(default="INFO", description="Log level: INFO, WARN, ERROR, DEBUG")

    message: str = Field(..., description="The actual log message")

    timestamp: Optional[str] = Field(default_factory=lambda: datetime.utcnow().isoformat())

    context: Optional[Dict[str, Any]] = Field(default=None, description="Optional metadata or context")

