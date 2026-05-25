"""
Repository for enrollment database operations.
"""
from typing import List
from prisma.models import Enrollment
from app.db.client import db


class EnrollmentRepository:
    """Handles CRUD operations for enrollments."""
    
    async def get_by_student_id(self, student_id: str) -> List[Enrollment]:
        """Get all enrollments for a student."""
        return await db.enrollment.find_many(
            where={"studentId": student_id},
            include={"academicClass": True}
        )
    
    async def get_by_class_id(self, class_id: str) -> List[Enrollment]:
        """Get all enrollments for a class."""
        return await db.enrollment.find_many(
            where={"academicClassId": class_id},
            include={"student": True}
        )

    async def enroll_student(self, student_id: str, class_id: str) -> Enrollment:
        """Enroll a student in a class."""
        return await db.enrollment.create(
            data={
                "studentId": student_id,
                "academicClassId": class_id
            }
        )
