from fastapi import APIRouter, status
from app.schemas.log import LogEvent
from app.core.logging_config import get_logger
import logging

router = APIRouter(prefix="/logs", tags=["Logging"])

logger = get_logger("app.client")


@router.post("", status_code=status.HTTP_200_OK)
async def ingest_log(log_event: LogEvent) -> dict:
    source = log_event.source
    lvl = getattr(logging, log_event.level.upper(), logging.INFO)
    msg = f"[{log_event.source}] [{log_event.timestamp}] {log_event.message}"
    logger.log(lvl, "%s", msg)
    return {"status": "success"}
