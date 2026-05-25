from typing import Optional, List

from prisma.models import AcademicClass

from app.db.client import db

class ClassRepository:

    async def get_by_id(self, class_id: str) -> Optional[AcademicClass]:

        return await db.academicclass.find_unique(where={"id": class_id})

    async def get_by_teacher_id(self, teacher_id: str) -> List[AcademicClass]:

        return await db.academicclass.find_many(where={"teacherId": teacher_id})

    async def create(self, name: str, subject: str, teacher_id: str) -> AcademicClass:

        return await db.academicclass.create(

            data={

                "name": name,

                "subject": subject,

                "teacherId": teacher_id

            }

        )

    async def update_teacher(self, class_id: str, teacher_id: str) -> AcademicClass:

        return await db.academicclass.update(

            where={"id": class_id},

            data={"teacherId": teacher_id}

        )

