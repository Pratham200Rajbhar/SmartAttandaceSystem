from typing import Optional
from prisma.models import User
from app.db.client import db


class UserRepository:



    async def get_by_email(self, email: str) -> Optional[User]:


        return await db.user.find_unique(where={"email": email})

    async def get_by_id(self, user_id: str) -> Optional[User]:


        return await db.user.find_unique(where={"id": user_id})

    async def create(self, email: str, password_hash: str, role: str) -> User:


        return await db.user.create(
            data={
                "email": email,
                "hashedPassword": password_hash,
                "role": role,
            }
        )
