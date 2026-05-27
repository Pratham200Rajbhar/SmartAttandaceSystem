from fastapi import HTTPException, status

from app.db.client import db
from app.repositories.student_repo import StudentRepository
from app.schemas.student import StudentAttendanceItem, StudentAttendanceHistoryResponse, StudentClassResponse


class StudentService:
    def __init__(self) -> None:
        self.student_repo = StudentRepository()

    async def get_student_by_user_id(self, user_id: str):
        student = await self.student_repo.get_by_user_id(user_id)
        if not student:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student profile not found.")
        return student

    async def get_student_classes(self, user_id: str) -> list[StudentClassResponse]:
        student = await self.get_student_by_user_id(user_id)
        enrollments = await db.enrollment.find_many(
            where={"studentId": student.id},
            include={
                "academicClass": {
                    "include": {"subject": True, "teacher": True, "geofence": True, "sessions": {"where": {"isActive": True}}}
                }
            },
        )
        return [
            StudentClassResponse(
                class_id=e.academicClass.id,
                class_name=e.academicClass.name,
                subject=e.academicClass.subject.name if e.academicClass.subject else "—",
                teacher_name=f"{e.academicClass.teacher.firstName} {e.academicClass.teacher.lastName}" if e.academicClass.teacher else "—",
                active_session_id=(s := e.academicClass.sessions)[0].id if e.academicClass.sessions else None,
                session_end_time=s[0].endTime if e.academicClass.sessions else None,
                latitude=e.academicClass.geofence.latitude if e.academicClass.geofence else None,
                longitude=e.academicClass.geofence.longitude if e.academicClass.geofence else None,
                radius_meters=e.academicClass.geofence.radiusMeters if e.academicClass.geofence else None,
            )
            for e in enrollments
        ]

    async def get_student_attendance_history(self, user_id: str) -> StudentAttendanceHistoryResponse:
        student = await self.get_student_by_user_id(user_id)
        enrollments = await db.enrollment.find_many(
            where={"studentId": student.id}, include={"academicClass": True}
        )
        class_ids = [e.academicClassId for e in enrollments]

        overall_percentage = 0.0
        if class_ids:
            total_sessions = await db.session.count(where={"academicClassId": {"in": class_ids}})
            if total_sessions > 0:
                present_count = await db.attendance.count(
                    where={"studentId": student.id, "status": {"in": ["Present", "Approved"]}}
                )
                overall_percentage = round((present_count / total_sessions) * 100.0, 2)

        records = await db.attendance.find_many(
            where={"studentId": student.id},
            include={"session": {"include": {"academicClass": {"include": {"subject": True}}}}},
            order={"createdAt": "desc"},
        )

        return StudentAttendanceHistoryResponse(
            student_id=student.id,
            overall_attendance_percentage=overall_percentage,
            history=[
                StudentAttendanceItem(
                    attendance_id=r.id,
                    class_id=ac.id,
                    class_name=ac.name,
                    subject=ac.subject.name if ac.subject and hasattr(ac.subject, 'name') else "—",
                    session_id=r.session.id,
                    status=r.status,
                    marked_at=r.createdAt,
                    face_score=r.faceScore,
                    liveness_score=r.livenessScore,
                    background_score=r.backgroundScore,
                    final_ai_score=r.finalAiScore,
                    teacher_note=r.remarks,
                )
                for r in records if (ac := r.session.academicClass)
            ],
        )
