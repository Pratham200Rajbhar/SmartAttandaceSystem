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

    backend_logger = logging.getLogger("app")
    backend_logger.setLevel(effective_level)
    backend_logger.propagate = False
    backend_logger.handlers.clear()
    backend_logger.addHandler(console)
    backend_logger.addHandler(backend_handler)

    access_logger = logging.getLogger("app.access")
    access_logger.setLevel(effective_level)
    access_logger.propagate = False
    access_logger.handlers.clear()
    access_logger.addHandler(console)
    access_logger.addHandler(access_handler)

    for name in _SILENCED_LOGGERS:
        logging.getLogger(name).setLevel(logging.ERROR)


def get_logger(name: str) -> logging.Logger:
    return logging.getLogger(name)
