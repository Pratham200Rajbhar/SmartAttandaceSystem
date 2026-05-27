import time
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from app.core.logging_config import get_logger

logger = get_logger("app.access")


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next) -> Response:
        start_ts = time.perf_counter()
        method = request.method
        path = request.url.path

        try:
            response: Response = await call_next(request)
        except Exception as exc:
            elapsed_ms = int((time.perf_counter() - start_ts) * 1000)
            logger.error("%s %s — %dms | error=%s", method, path, elapsed_ms, exc, exc_info=True)
            raise

        elapsed_ms = int((time.perf_counter() - start_ts) * 1000)
        log = logger.warning if response.status_code >= 400 else logger.info
        log("%s %s %d %dms", method, path, response.status_code, elapsed_ms)
        return response
