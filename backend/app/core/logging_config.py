import logging
from pathlib import Path

# Define root project directory (2 levels up from backend/app/core, so it's in backend, then 1 more level up)
# Wait: backend/app/core -> backend/app -> backend -> root
ROOT_DIR = Path(__file__).resolve().parent.parent.parent.parent
LOGS_DIR = ROOT_DIR / "logs"

def setup_logging():
    # Create logs directory if it doesn't exist
    LOGS_DIR.mkdir(parents=True, exist_ok=True)

    log_format = logging.Formatter("%(asctime)s [%(levelname)s] [%(name)s] %(message)s")

    # 1. Backend Logger
    backend_logger = logging.getLogger("app")
    backend_logger.setLevel(logging.INFO)
    backend_logger.propagate = False
    
    # Also attach a console handler to the backend logger for local dev visibility
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(log_format)
    
    # File handler with mode='a' to append
    backend_file = logging.FileHandler(LOGS_DIR / "backend.log", mode="a")
    backend_file.setFormatter(log_format)
    
    # Clear existing handlers
    if backend_logger.hasHandlers():
        backend_logger.handlers.clear()
        
    backend_logger.addHandler(console_handler)
    backend_logger.addHandler(backend_file)

    # 2. Frontend Logger
    frontend_logger = logging.getLogger("frontend")
    frontend_logger.setLevel(logging.INFO)
    frontend_logger.propagate = False
    
    frontend_file = logging.FileHandler(LOGS_DIR / "frontend.log", mode="a")
    frontend_file.setFormatter(log_format)
    
    if frontend_logger.hasHandlers():
        frontend_logger.handlers.clear()
        
    frontend_logger.addHandler(frontend_file)

    # 3. Mobile Logger
    mobile_logger = logging.getLogger("mobile")
    mobile_logger.setLevel(logging.INFO)
    mobile_logger.propagate = False
    
    mobile_file = logging.FileHandler(LOGS_DIR / "mobile.log", mode="a")
    mobile_file.setFormatter(log_format)
    
    if mobile_logger.hasHandlers():
        mobile_logger.handlers.clear()
        
    mobile_logger.addHandler(mobile_file)
    
    # General fallback for uvicorn etc (optional, but good practice)
    # We will let Uvicorn handle its own logs, but we can capture root
    root_logger = logging.getLogger()
    if not root_logger.hasHandlers():
        root_logger.setLevel(logging.WARNING)
        root_logger.addHandler(console_handler)

    backend_logger.info("Centralized logging initialized. Outputting to %s", LOGS_DIR)

def get_frontend_logger():
    return logging.getLogger("frontend")

def get_mobile_logger():
    return logging.getLogger("mobile")
