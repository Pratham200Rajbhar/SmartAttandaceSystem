from typing import List

from prisma.models import Attendance
from app.db.client import db


class AttendanceRepository:
    async def get_by_id(self, attendance_id: str) -> Attendance | None:
        return await db.attendance.find_unique(
            where={"id": attendance_id},
            include={
                "student": {"include": {"user": True}},
                "session": {"include": {"academicClass": {"include": {"subject": True}}}},
            },
        )

    async def get_by_student_and_session(self, student_id: str, session_id: str) -> Attendance | None:
        return await db.attendance.find_unique(
            where={"studentId_sessionId": {"studentId": student_id, "sessionId": session_id}}
        )

    async def get_flagged(self) -> List[Attendance]:
        return await db.attendance.find_many(
            where={"status": "Flagged"},
            include={
                "student": {"include": {"user": True}},
                "session": {"include": {"academicClass": {"include": {"subject": True}}}},
            },
        )

    async def create(self, data_dict: dict) -> Attendance:
        return await db.attendance.create(data=data_dict)

    async def update_review(self, attendance_id: str, status: str, remarks: str) -> Attendance:
        return await db.attendance.update(
            where={"id": attendance_id}, data={"status": status, "remarks": remarks}
        )

    async def get_all_absences(self) -> List[Attendance]:
        return await db.attendance.find_many(
            where={"status": {"in": ["Absent", "Rejected"]}}, include={"student": True}
        )

    async def get_by_student_id(self, student_id: str) -> List[Attendance]:
        return await db.attendance.find_many(
            where={"studentId": student_id},
            include={"session": {"include": {"academicClass": True}}},
            order={"createdAt": "desc"},
        )

    async def get_by_session_id(self, session_id: str) -> List[Attendance]:
        return await db.attendance.find_many(
            where={"sessionId": session_id}, include={"student": True}
        )

    async def get_by_student_in_date_range(self, student_id: str, start_date, end_date) -> List[Attendance]:
        return await db.attendance.find_many(
            where={"studentId": student_id, "createdAt": {"gte": start_date, "lte": end_date}},
            include={"session": True},
            order={"createdAt": "desc"},
        )

    async def update(self, attendance_id: str, data: dict) -> Attendance:
        return await db.attendance.update(where={"id": attendance_id}, data=data)
