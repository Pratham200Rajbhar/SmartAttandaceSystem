import logging

from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent.parent.parent

LOGS_DIR = ROOT_DIR / "logs"

def setup_logging():

    LOGS_DIR.mkdir(parents=True, exist_ok=True)

    log_format = logging.Formatter("%(asctime)s [%(levelname)s] [%(name)s] %(message)s")

    backend_logger = logging.getLogger("app")

    backend_logger.setLevel(logging.INFO)

    backend_logger.propagate = False

    console_handler = logging.StreamHandler()

    console_handler.setFormatter(log_format)

    backend_file = logging.FileHandler(LOGS_DIR / "backend.log", mode="a")

    backend_file.setFormatter(log_format)

    if backend_logger.hasHandlers():

        backend_logger.handlers.clear()

    backend_logger.addHandler(console_handler)

    backend_logger.addHandler(backend_file)

    frontend_logger = logging.getLogger("frontend")

    frontend_logger.setLevel(logging.INFO)

    frontend_logger.propagate = False

    frontend_file = logging.FileHandler(LOGS_DIR / "frontend.log", mode="a")

    frontend_file.setFormatter(log_format)

    if frontend_logger.hasHandlers():

        frontend_logger.handlers.clear()

    frontend_logger.addHandler(frontend_file)

    mobile_logger = logging.getLogger("mobile")

    mobile_logger.setLevel(logging.INFO)

    mobile_logger.propagate = False

    mobile_file = logging.FileHandler(LOGS_DIR / "mobile.log", mode="a")

    mobile_file.setFormatter(log_format)

    if mobile_logger.hasHandlers():

        mobile_logger.handlers.clear()

    mobile_logger.addHandler(mobile_file)

    root_logger = logging.getLogger()

    if not root_logger.hasHandlers():

        root_logger.setLevel(logging.WARNING)

        root_logger.addHandler(console_handler)

    backend_logger.info("Centralized logging initialized. Outputting to %s", LOGS_DIR)

def get_frontend_logger():

    return logging.getLogger("frontend")

def get_mobile_logger():

    return logging.getLogger("mobile")

