import time
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp
from app.core.logging_config import get_logger

logger = get_logger("app.access")


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    def __init__(self, app: ASGIApp) -> None:
        super().__init__(app)

    async def dispatch(self, request: Request, call_next) -> Response:
        start_ts = time.perf_counter()
        client_ip = request.headers.get("x-forwarded-for", request.client.host if request.client else "unknown").split(",")[0].strip()
        method = request.method
        path = request.url.path

        try:
            response: Response = await call_next(request)
        except Exception as exc:
            elapsed_ms = int((time.perf_counter() - start_ts) * 1000)
            logger.error("%s %s — %dms | error=%s", method, path, elapsed_ms, exc, exc_info=True)
            raise

        elapsed_ms = int((time.perf_counter() - start_ts) * 1000)
        if response.status_code >= 400:
            logger.warning("%s %s %d %dms", method, path, response.status_code, elapsed_ms)
        else:
            logger.info("%s %s %d %dms", method, path, response.status_code, elapsed_ms)

        return response
