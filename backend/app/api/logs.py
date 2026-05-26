"""
Log ingestion endpoint.

Accepts structured log events from the frontend (Next.js) and mobile (Flutter)
clients and routes them to the appropriate dedicated log file via the Python
logging hierarchy configured in app.core.logging_config.
"""

from fastapi import APIRouter, status
from pydantic import ValidationError

from app.schemas.log import LogEvent
from app.core.logging_config import get_frontend_logger, get_mobile_logger, get_logger

import logging

router = APIRouter(prefix="/logs", tags=["Logging"])

_fallback_logger = get_logger("app.logs")


def _emit(logger: logging.Logger, level: str, message: str) -> None:
    """Dispatch a log message at the correct level."""
    dispatch = {
        "DEBUG": logger.debug,
        "INFO": logger.info,
        "WARN": logger.warning,
        "WARNING": logger.warning,
        "ERROR": logger.error,
        "CRITICAL": logger.critical,
    }
    dispatch.get(level, logger.info)(message)


@router.post("", status_code=status.HTTP_200_OK)
async def ingest_log(log_event: LogEvent) -> dict:
    """
    Ingest a structured log event from a client application.

    The source field determines which log file receives the entry:
    - 'frontend'  →  logs/frontend.log
    - 'mobile'    →  logs/mobile.log
    """
    source = log_event.source  # already validated & lowercased by the schema

    if source == "frontend":
        logger = get_frontend_logger()
    else:
        logger = get_mobile_logger()

    # Build a structured message that includes all enriched fields
    parts = [f"[{log_event.timestamp}]", log_event.message]

    if log_event.user_id:
        parts.append(f"| user_id={log_event.user_id}")

    if log_event.platform_version:
        parts.append(f"| platform={log_event.platform_version}")

    if log_event.context:
        context_str = " ".join(f"{k}={v}" for k, v in log_event.context.items())
        parts.append(f"| {context_str}")

    log_msg = " ".join(parts)
    _emit(logger, log_event.level, log_msg)

    return {"status": "success", "message": "Log recorded"}
