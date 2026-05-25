import os

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'

os.environ['CUDA_VISIBLE_DEVICES'] = '-1'

import logging

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

from app.core.logging_config import setup_logging

setup_logging()

logger = logging.getLogger("app.main")

@asynccontextmanager

async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:

    logger.info("Initializing Smart Attendance System Server...")

    await connect_db()

    await connect_redis()

    yield

    logger.info("Stopping Smart Attendance System Server...")

    await disconnect_db()

    await disconnect_redis()

app = FastAPI(

    title=settings.PROJECT_NAME,

    description="Asynchronous AI-powered Multi-Layered Smart Attendance verification backend.",

    version="1.0.0",

    docs_url="/docs",

    redoc_url="/redoc",

    lifespan=lifespan

)

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

        "CRITICAL ERROR on %s %s: %s",

        request.method,

        request.url.path,

        exc,

        exc_info=True

    )

    return JSONResponse(

        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,

        content={"detail": "Something went wrong"}

    )

@app.get("/health", tags=["System Maintenance"], status_code=status.HTTP_200_OK)

async def system_health_check() -> dict:

    return {"status": "healthy", "service": settings.PROJECT_NAME}

