from fastapi import HTTPException, status
from app.repositories.student_repo import StudentRepository
from app.schemas.student import (
    StudentAttendanceItem,
    StudentAttendanceHistoryResponse,
    StudentClassResponse
)
from app.db.client import db


class StudentService:



    def __init__(self) -> None:
        self.student_repo = StudentRepository()

    async def get_student_by_user_id(self, user_id: str):


        student = await self.student_repo.get_by_user_id(user_id)
        if not student:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Student profile not found."
            )
        return student

    async def get_student_classes(self, user_id: str) -> list[StudentClassResponse]:
        student = await self.get_student_by_user_id(user_id)
        
        enrollments = await db.enrollment.find_many(
            where={"studentId": student.id},
            include={
                "academicClass": {
                    "include": {
                        "subject": True,
                        "teacher": True,
                        "sessions": {
                            "where": {"isActive": True}
                        }
                    }
                }
            }
        )
        
        class_responses = []
        for enroll in enrollments:
            aclass = enroll.academicClass
            subject_name = aclass.subject.name if aclass.subject else "—"
            teacher_name = f"{aclass.teacher.firstName} {aclass.teacher.lastName}" if aclass.teacher else "—"
            
            active_session_id = None
            session_end_time = None
            if aclass.sessions and len(aclass.sessions) > 0:
                active_session = aclass.sessions[0]
                active_session_id = active_session.id
                session_end_time = active_session.endTime if hasattr(active_session, 'endTime') else None
                
            class_responses.append(StudentClassResponse(
                class_id=aclass.id,
                class_name=aclass.name,
                subject=subject_name,
                teacher_name=teacher_name,
                active_session_id=active_session_id,
                session_end_time=session_end_time,
            ))
            
        return class_responses

    async def get_student_attendance_history(self, user_id: str) -> StudentAttendanceHistoryResponse:



        student = await self.get_student_by_user_id(user_id)


        enrollments = await db.enrollment.find_many(
            where={"studentId": student.id},
            include={"academicClass": True}
        )

        class_ids = [enroll.academicClassId for enroll in enrollments]


        overall_percentage = 100.0
        if len(class_ids) > 0:
            total_sessions = await db.session.count(
                where={"academicClassId": {"in": class_ids}}
            )
            
            if total_sessions > 0:
                present_count = await db.attendance.count(
                    where={
                        "studentId": student.id,
                        "status": {"in": ["Present", "Approved"]}
                    }
                )
                overall_percentage = round((present_count / total_sessions) * 100.0, 2)


        attendance_records = await db.attendance.find_many(
            where={"studentId": student.id},
            include={"session": {"include": {"academicClass": {"include": {"subject": True}}}}},
            order={"createdAt": "desc"}
        )

        history_items = []
        for rec in attendance_records:
            session = rec.session
            academic_class = session.academicClass
            history_items.append(
                StudentAttendanceItem(
                    attendance_id=rec.id,
                    class_id=academic_class.id,
                    class_name=academic_class.name,
                    subject=academic_class.subject.name if academic_class.subject and hasattr(academic_class.subject, 'name') else "—",
                    session_id=session.id,
                    status=rec.status,
                    marked_at=rec.createdAt,
                    face_score=rec.faceScore,
                    liveness_score=rec.livenessScore,
                    background_score=rec.backgroundScore,
                    final_ai_score=rec.finalAiScore,
                    teacher_note=rec.remarks,
                )
            )

        return StudentAttendanceHistoryResponse(
            student_id=student.id,
            overall_attendance_percentage=overall_percentage,
            history=history_items
        )
