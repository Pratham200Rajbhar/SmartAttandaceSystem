import os

# Suppress TensorFlow/CUDA noise before any imports load those libraries
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'
os.environ['CUDA_VISIBLE_DEVICES'] = '-1'

# Initialize the unified logging system first — before any other app modules
# are imported so that every logger created during module load picks up the
# configured handlers and the log files are truncated for a fresh session.
from app.core.logging_config import setup_logging, get_logger

setup_logging()

logger = get_logger("app.main")

from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse

from app.core.config import settings
from app.db.client import connect_db, disconnect_db
from app.db.redis import connect_redis, disconnect_redis
from app.api import auth, student, teacher, admin, logs, ws
from app.middleware.request_logging import RequestLoggingMiddleware


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    logger.info("=== Smart Attendance System — Server Starting ===")
    await connect_db()
    await connect_redis()
    logger.info("All services connected. Server is ready to accept requests.")
    yield
    logger.info("=== Smart Attendance System — Server Shutting Down ===")
    await disconnect_db()
    await disconnect_redis()
    logger.info("All services disconnected. Shutdown complete.")


app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Asynchronous AI-powered Multi-Layered Smart Attendance verification backend.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# Request logging must be added before CORS so every request — including
# preflight OPTIONS — is captured in the access log.
app.add_middleware(RequestLoggingMiddleware)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix=settings.API_V1_STR)
app.include_router(student.router, prefix=settings.API_V1_STR)
app.include_router(teacher.router, prefix=settings.API_V1_STR)
app.include_router(admin.router, prefix=settings.API_V1_STR)
app.include_router(logs.router, prefix=settings.API_V1_STR)
app.include_router(ws.router, prefix=settings.API_V1_STR)

os.makedirs("static/proofs", exist_ok=True)
os.makedirs("static/leaves", exist_ok=True)

app.mount("/static", StaticFiles(directory="static"), name="static")


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    logger.critical(
        "Unhandled exception on %s %s: %s",
        request.method,
        request.url.path,
        exc,
        exc_info=True,
    )
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Something went wrong"},
    )


@app.get("/health", tags=["System Maintenance"], status_code=status.HTTP_200_OK)
async def system_health_check() -> dict:
    return {"status": "healthy", "service": settings.PROJECT_NAME}
