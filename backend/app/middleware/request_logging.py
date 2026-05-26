"""
HTTP request/response logging middleware.

Logs every inbound request and its completed response to the 'app.access' logger,
which routes to logs/access.log. Captures method, path, status code, client IP,
and total round-trip duration in milliseconds.
"""

import time

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp

from app.core.logging_config import get_logger

logger = get_logger("app.access")


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """Middleware that emits one structured log line per HTTP request."""

    def __init__(self, app: ASGIApp) -> None:
        super().__init__(app)

    async def dispatch(self, request: Request, call_next) -> Response:
        start_ts = time.perf_counter()

        client_ip = self._resolve_client_ip(request)
        method = request.method
        path = request.url.path
        query = f"?{request.url.query}" if request.url.query else ""

        try:
            response: Response = await call_next(request)
            status_code = response.status_code
        except Exception as exc:
            elapsed_ms = int((time.perf_counter() - start_ts) * 1000)
            logger.error(
                "%s %s%s — UNHANDLED EXCEPTION after %dms | ip=%s | error=%s",
                method,
                path,
                query,
                elapsed_ms,
                client_ip,
                exc,
                exc_info=True,
            )
            raise

        elapsed_ms = int((time.perf_counter() - start_ts) * 1000)

        log_fn = logger.warning if status_code >= 400 else logger.info
        log_fn(
            "%s %s%s %d %dms | ip=%s",
            method,
            path,
            query,
            status_code,
            elapsed_ms,
            client_ip,
        )

        return response

    @staticmethod
    def _resolve_client_ip(request: Request) -> str:
        """
        Resolve the real client IP, honouring the X-Forwarded-For header
        set by reverse proxies (nginx, Vercel, etc.).
        """
        forwarded_for = request.headers.get("x-forwarded-for")
        if forwarded_for:
            # The header may contain a comma-separated list; take the first entry
            return forwarded_for.split(",")[0].strip()
        if request.client:
            return request.client.host
        return "unknown"
