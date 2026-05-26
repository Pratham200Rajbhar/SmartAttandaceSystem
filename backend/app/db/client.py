from app.core.logging_config import get_logger
from prisma import Prisma

logger = get_logger("app.db")

db = Prisma()

async def connect_db() -> None:

    try:

        await db.connect()

        logger.info("Successfully connected to the database via Prisma.")

    except Exception as e:

        logger.error("Failed to connect to the database via Prisma: %s", e)

        raise e

async def disconnect_db() -> None:

    try:

        if db.is_connected():

            await db.disconnect()

            logger.info("Successfully disconnected from the database via Prisma.")

    except Exception as e:

        logger.error("Error during database disconnection: %s", e)

