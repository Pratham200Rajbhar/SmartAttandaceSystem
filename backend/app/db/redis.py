from redis.asyncio import Redis
from app.core.config import settings
from app.core.logging_config import get_logger

logger = get_logger("app.redis")

redis_client: Redis | None = None


async def connect_redis() -> Redis:
    global redis_client
    if redis_client is None:
        try:
            redis_client = Redis.from_url(settings.REDIS_URL, decode_responses=True)
            await redis_client.ping()
            logger.info("Connected to Redis")
        except Exception as err:
            logger.error("Failed to connect to Redis at %s: %s", settings.REDIS_URL, err, exc_info=True)
            redis_client = None
            raise
    return redis_client


async def disconnect_redis() -> None:
    global redis_client
    if redis_client is not None:
        try:
            await redis_client.close()
        except Exception as err:
            logger.error("Error closing Redis connection: %s", err, exc_info=True)
        finally:
            redis_client = None


def get_redis() -> Redis:
    if redis_client is None:
        raise RuntimeError("Redis client is not initialized. Please call connect_redis during startup.")
    return redis_client

