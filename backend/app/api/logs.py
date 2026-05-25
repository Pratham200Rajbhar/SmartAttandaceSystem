from fastapi import APIRouter, status

from app.schemas.log import LogEvent

from app.core.logging_config import get_frontend_logger, get_mobile_logger

import logging

router = APIRouter(prefix="/logs", tags=["Logging"])

@router.post("", status_code=status.HTTP_200_OK)

async def ingest_log(log_event: LogEvent):

    if log_event.source.lower() == "frontend":

        logger = get_frontend_logger()

    elif log_event.source.lower() == "mobile":

        logger = get_mobile_logger()

    else:

        logger = logging.getLogger("app.unknown_source")

    context_str = f" | Context: {log_event.context}" if log_event.context else ""

    log_msg = f"[{log_event.timestamp}] {log_event.message}{context_str}"

    level = log_event.level.upper()

    if level == "INFO":

        logger.info(log_msg)

    elif level in ["WARN", "WARNING"]:

        logger.warning(log_msg)

    elif level == "ERROR":

        logger.error(log_msg)

    elif level == "DEBUG":

        logger.debug(log_msg)

    elif level == "CRITICAL":

        logger.critical(log_msg)

    else:

        logger.info(log_msg)

    return {"status": "success", "message": "Log recorded"}

