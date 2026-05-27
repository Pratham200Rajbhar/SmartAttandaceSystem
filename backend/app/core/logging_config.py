import logging
from logging.handlers import TimedRotatingFileHandler
from pathlib import Path

_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent
LOGS_DIR = _PROJECT_ROOT / "logs"

_SILENCED_LOGGERS = [
    "uvicorn.access", "httpx", "httpcore", "deepface",
    "tensorflow", "absl", "h5py", "PIL", "numba",
    "huggingface_hub", "filelock", "urllib3", "werkzeug", "asyncio",
]

_FORMAT = logging.Formatter(
    "%(asctime)s [%(levelname)-8s] [%(name)s] %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)

_ACCESS_FORMAT = logging.Formatter(
    "%(asctime)s [ACCESS   ] %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)


def setup_logging(level: str | None = None) -> None:
    if level is None:
        from app.core.config import settings
        level = settings.LOG_LEVEL

    effective_level = getattr(logging, level.upper(), logging.DEBUG)
    LOGS_DIR.mkdir(parents=True, exist_ok=True)

    backend_handler = TimedRotatingFileHandler(
        filename=LOGS_DIR / "backend.log",
        when="midnight", backupCount=7, encoding="utf-8",
    )
    backend_handler.setFormatter(_FORMAT)

    access_handler = TimedRotatingFileHandler(
        filename=LOGS_DIR / "access.log",
        when="midnight", backupCount=7, encoding="utf-8",
    )
    access_handler.setFormatter(_ACCESS_FORMAT)

    console = logging.StreamHandler()
    console.setFormatter(_FORMAT)

    for logger_name, handler in [("app", backend_handler), ("app.access", access_handler)]:
        logger = logging.getLogger(logger_name)
        logger.setLevel(effective_level)
        logger.propagate = False
        logger.handlers.clear()
        logger.addHandler(console)
        logger.addHandler(handler)

    for name in _SILENCED_LOGGERS:
        logging.getLogger(name).setLevel(logging.ERROR)


def get_logger(name: str) -> logging.Logger:
    return logging.getLogger(name)
