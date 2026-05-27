import os

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'
os.environ['CUDA_VISIBLE_DEVICES'] = '-1'

from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse

from app.core.config import settings
from app.core.logging_config import setup_logging, get_logger
from app.db.client import connect_db, disconnect_db, db
from app.db.redis import connect_redis, disconnect_redis, get_redis
from app.api import auth, student, teacher, admin, logs, ws as ws_module
from app.middleware.request_logging import RequestLoggingMiddleware

setup_logging(level=settings.LOG_LEVEL)
logger = get_logger("app.main")


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    logger.info("Starting server...")
    await connect_db()
    await connect_redis()
    ws_module.manager.start_heartbeat()
    logger.info("Server ready")
    yield
    logger.info("Shutting down...")
    ws_module.manager.stop_heartbeat()
    await disconnect_db()
    await disconnect_redis()
    logger.info("Shutdown complete")


app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Asynchronous AI-powered Multi-Layered Smart Attendance verification backend.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

app.add_middleware(RequestLoggingMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.FRONTEND_URL.split(",") if "," in settings.FRONTEND_URL else [settings.FRONTEND_URL],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix=settings.API_V1_STR)
app.include_router(student.router, prefix=settings.API_V1_STR)
app.include_router(teacher.router, prefix=settings.API_V1_STR)
app.include_router(admin.router, prefix=settings.API_V1_STR)
app.include_router(logs.router, prefix=settings.API_V1_STR)
app.include_router(ws_module.router, prefix=settings.API_V1_STR)

os.makedirs("static/proofs", exist_ok=True)
os.makedirs("static/leaves", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    logger.critical("Unhandled exception: %s %s — %s", request.method, request.url.path, exc, exc_info=True)
    return JSONResponse(status_code=500, content={"detail": "Something went wrong"})


@app.get("/health", tags=["System Maintenance"], status_code=status.HTTP_200_OK)
async def system_health_check() -> dict:
    db_ok = False
    redis_ok = False
    try:
        await db.user.count()
        db_ok = True
    except Exception:
        pass
    try:
        r = await get_redis()
        await r.ping()
        redis_ok = True
    except Exception:
        pass
    overall = "healthy" if db_ok and redis_ok else "degraded"
    return {"status": overall, "service": settings.PROJECT_NAME, "database": "ok" if db_ok else "unreachable", "redis": "ok" if redis_ok else "unreachable"}
