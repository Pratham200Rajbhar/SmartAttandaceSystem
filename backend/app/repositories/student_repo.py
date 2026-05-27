from typing import List

from prisma.models import Student
from app.db.client import db


class StudentRepository:
    async def get_by_id(self, student_id: str) -> Student | None:
        return await db.student.find_unique(where={"id": student_id}, include={"user": True})

    async def get_by_user_id(self, user_id: str) -> Student | None:
        return await db.student.find_unique(where={"userId": user_id}, include={"user": True})

    async def get_by_enrollment(self, enrollment: str) -> Student | None:
        return await db.student.find_unique(where={"enrollmentNumber": enrollment}, include={"user": True})

    async def create(self, user_id: str, enrollment: str) -> Student:
        return await db.student.create(data={"userId": user_id, "enrollmentNumber": enrollment})

    async def update_face_embedding(self, student_id: str, embedding: List[float]) -> bool:
        await db.execute_raw("UPDATE students SET face_embedding = $1::vector WHERE id = $2", embedding, student_id)
        return True

    async def get_face_embedding(self, student_id: str) -> List[float] | None:
        records = await db.query_raw("SELECT face_embedding::text FROM students WHERE id = $1", student_id)
        if not records or not records[0].get("face_embedding"):
            return None
        val = records[0]["face_embedding"]
        if isinstance(val, list):
            return [float(x) for x in val]
        if isinstance(val, str):
            cleaned = val.strip("[]")
            return [float(x) for x in cleaned.split(",")] if cleaned else []
        return None

    async def update_streak(self, student_id: str, current_streak: int, highest_streak: int) -> bool:
        await db.student.update(
            where={"id": student_id},
            data={"currentStreak": current_streak, "highestStreak": highest_streak},
        )
        return True

    async def get_all_active(self) -> List[Student]:
        return await db.student.find_many(
            where={"user": {"is": {"isActive": True}}},
            include={"user": True},
        )
