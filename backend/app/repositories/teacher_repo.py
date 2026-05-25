from typing import Optional

from prisma.models import Teacher

from app.db.client import db

class TeacherRepository:

    async def get_by_id(self, teacher_id: str) -> Optional[Teacher]:

        return await db.teacher.find_unique(

            where={"id": teacher_id},

            include={"user": True}

        )

    async def get_by_user_id(self, user_id: str) -> Optional[Teacher]:

        return await db.teacher.find_unique(

            where={"userId": user_id},

            include={"user": True}

        )

    async def create(self, user_id: str, department: str, designation: str) -> Teacher:

        return await db.teacher.create(

            data={

                "userId": user_id,

                "department": department,

                "designation": designation

            }

        )

