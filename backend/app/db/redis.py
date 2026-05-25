import logging
from typing import Optional
from redis.asyncio import Redis
from app.core.config import settings

logger = logging.getLogger("app.redis")


redis_client: Optional[Redis] = None


async def connect_redis() -> Redis:


    global redis_client
    if redis_client is None:
        logger.info(f"Establishing connection to Redis at {settings.REDIS_URL}...")
        try:
            redis_client = Redis.from_url(settings.REDIS_URL, decode_responses=True)
            await redis_client.ping()
            logger.info("✅ Successfully connected to Redis.")
        except Exception as err:
            logger.error(f"❌ Failed to connect to Redis at {settings.REDIS_URL}: {err}")
            redis_client = None
            raise err
    return redis_client


async def disconnect_redis() -> None:


    global redis_client
    if redis_client is not None:
        logger.info("Closing asynchronous Redis connection...")
        try:
            await redis_client.close()
            logger.info("✅ Redis connection closed successfully.")
        except Exception as err:
            logger.error(f"Error closing Redis connection: {err}")
        finally:
            redis_client = None


def get_redis() -> Redis:


    if redis_client is None:
        raise RuntimeError("Redis client is not initialized. Please call connect_redis during startup.")
    return redis_client
