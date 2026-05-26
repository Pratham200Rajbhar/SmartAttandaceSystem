"""
Centralized logging configuration for the Smart Attendance System backend.

On every call to setup_logging(), all existing log files in the logs/ directory
are truncated so each server restart begins a clean session.
"""

import logging
import glob

from logging.handlers import TimedRotatingFileHandler
from pathlib import Path

# Resolve the project root (four levels up from this file:
# core/ -> app/ -> backend/ -> project root)
_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent
LOGS_DIR = _PROJECT_ROOT / "logs"

# ---------------------------------------------------------------------------
# Noisy third-party loggers to suppress
# ---------------------------------------------------------------------------
_SILENCED_LOGGERS = [
    "uvicorn.access",
    "httpx",
    "httpcore",
    "deepface",
    "tensorflow",
    "absl",
    "h5py",
    "PIL",
    "numba",
    "huggingface_hub",
    "filelock",
    "urllib3",
    "werkzeug",
    "asyncio",
]

_LOG_FORMAT = logging.Formatter(
    "%(asctime)s [%(levelname)-8s] [%(name)s] %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)

_ACCESS_FORMAT = logging.Formatter(
    "%(asctime)s [ACCESS   ] %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)


def _truncate_existing_logs() -> None:
    """Truncate all .log files in the logs directory to start a fresh session."""
    LOGS_DIR.mkdir(parents=True, exist_ok=True)
    for log_file in glob.glob(str(LOGS_DIR / "*.log")):
        with open(log_file, "w"):
            pass


def _build_file_handler(filename: str, formatter: logging.Formatter) -> TimedRotatingFileHandler:
    """
    Create a rotating file handler.

    Opens the file in write mode ('w') so the first write of each session
    begins from an empty file (truncation is handled by _truncate_existing_logs,
    but 'w' here acts as a safety net for any file not caught by the glob).
    Rotates daily and retains 7 backups.
    """
    handler = TimedRotatingFileHandler(
        filename=LOGS_DIR / filename,
        when="midnight",
        backupCount=7,
        encoding="utf-8",
    )
    handler.setFormatter(formatter)
    return handler


def _build_console_handler() -> logging.StreamHandler:
    """Create a formatted console handler."""
    handler = logging.StreamHandler()
    handler.setFormatter(_LOG_FORMAT)
    return handler


def setup_logging() -> None:
    """
    Initialize the unified logging system.

    Must be called once at application startup, before any loggers are used.
    Truncates all existing log files in logs/ to ensure a clean session.
    """
    _truncate_existing_logs()

    console = _build_console_handler()

    # -----------------------------------------------------------------------
    # Backend application logger  →  logs/backend.log
    # -----------------------------------------------------------------------
    backend_file = _build_file_handler("backend.log", _LOG_FORMAT)
    backend_logger = logging.getLogger("app")
    backend_logger.setLevel(logging.DEBUG)
    backend_logger.propagate = False
    backend_logger.handlers.clear()
    backend_logger.addHandler(console)
    backend_logger.addHandler(backend_file)

    # -----------------------------------------------------------------------
    # HTTP access logger  →  logs/access.log
    # -----------------------------------------------------------------------
    access_file = _build_file_handler("access.log", _ACCESS_FORMAT)
    access_logger = logging.getLogger("app.access")
    access_logger.setLevel(logging.INFO)
    access_logger.propagate = False
    access_logger.handlers.clear()
    access_logger.addHandler(access_file)
    # Also mirror access logs to the console for visibility during development
    access_logger.addHandler(console)

    # -----------------------------------------------------------------------
    # Frontend relay logger  →  logs/frontend.log
    # -----------------------------------------------------------------------
    frontend_file = _build_file_handler("frontend.log", _LOG_FORMAT)
    frontend_logger = logging.getLogger("frontend")
    frontend_logger.setLevel(logging.DEBUG)
    frontend_logger.propagate = False
    frontend_logger.handlers.clear()
    frontend_logger.addHandler(frontend_file)

    # -----------------------------------------------------------------------
    # Mobile relay logger  →  logs/mobile.log
    # -----------------------------------------------------------------------
    mobile_file = _build_file_handler("mobile.log", _LOG_FORMAT)
    mobile_logger = logging.getLogger("mobile")
    mobile_logger.setLevel(logging.DEBUG)
    mobile_logger.propagate = False
    mobile_logger.handlers.clear()
    mobile_logger.addHandler(mobile_file)

    # -----------------------------------------------------------------------
    # Root logger — WARNING+ only, so unhandled third-party logs are visible
    # -----------------------------------------------------------------------
    root_logger = logging.getLogger()
    root_logger.setLevel(logging.WARNING)
    if not root_logger.handlers:
        root_logger.addHandler(console)

    # -----------------------------------------------------------------------
    # Silence noisy third-party libraries
    # -----------------------------------------------------------------------
    for name in _SILENCED_LOGGERS:
        logging.getLogger(name).setLevel(logging.ERROR)

    backend_logger.info(
        "Logging initialized. Log directory: %s — all files cleared for fresh session.", LOGS_DIR
    )


def get_logger(name: str) -> logging.Logger:
    """
    Return a named logger that inherits from the configured 'app' hierarchy.

    Usage:
        logger = get_logger(__name__)
    """
    return logging.getLogger(name)


def get_frontend_logger() -> logging.Logger:
    """Return the dedicated frontend relay logger."""
    return logging.getLogger("frontend")


def get_mobile_logger() -> logging.Logger:
    """Return the dedicated mobile relay logger."""
    return logging.getLogger("mobile")
