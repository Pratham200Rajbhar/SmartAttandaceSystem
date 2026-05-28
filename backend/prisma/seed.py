import asyncio
import sys
import os

# Ensure the parent directory is in the path to support app/scripts imports
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from scripts.seed_db import seed_all, seed_all_pratham

if __name__ == "__main__":
    seed_type = os.getenv("SEED_TYPE", "default").strip().lower()
    if seed_type == "pratham":
        asyncio.run(seed_all_pratham())
    else:
        asyncio.run(seed_all())

