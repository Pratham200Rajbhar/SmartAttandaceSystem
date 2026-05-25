import asyncio
import sys
import os

# Ensure the parent directory is in the path to support app/scripts imports
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from scripts.seed_db import seed_all

if __name__ == "__main__":
    asyncio.run(seed_all())
