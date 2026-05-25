from datetime import datetime

from typing import List, Optional

from fastapi import HTTPException, status

from app.repositories.teacher_repo import TeacherRepository

from app.repositories.class_repo import ClassRepository

from app.repositories.geofence_repo import GeofenceRepository

from app.schemas.teacher import (

    GeofenceUpsert,

    GeofenceResponse,

    AcademicClassWithGeofenceResponse,

    StudentRosterItem,

    SessionAttendanceResponse,

    ClassStatsResponse,

    SessionWithClassResponse,

    SessionTrendItem,

    BulkMarkRequest,

    AbsentStudentItem,

)

from app.db.client import db

class TeacherService:

    def __init__(self) -> None:

        self.teacher_repo = TeacherRepository()

        self.class_repo = ClassRepository()

        self.geofence_repo = GeofenceRepository()

    async def get_teacher_by_user_id(self, user_id: str):

        teacher = await self.teacher_repo.get_by_user_id(user_id)

        if not teacher:

            raise HTTPException(

                status_code=status.HTTP_404_NOT_FOUND,

                detail="Teacher profile not found.",

            )

        return teacher

    def _resolve_full_name(self, first: Optional[str], last: Optional[str]) -> str:

        return f"{first or ''} {last or ''}".strip() or "—"

    async def get_classes_by_teacher_user_id(

        self, user_id: str

    ) -> List[AcademicClassWithGeofenceResponse]:

        teacher = await self.get_teacher_by_user_id(user_id)

        classes = await db.academicclass.find_many(

            where={"teacherId": teacher.id},

            include={"geofence": True, "subject": True},

        )

        results = []

        for c in classes:

            results.append(

                AcademicClassWithGeofenceResponse(

                    id=c.id,

                    name=c.name,

                    subject=c.subject.name if c.subject else "—",

                    teacherId=c.teacherId,

                    geofence=GeofenceResponse.model_validate(c.geofence) if c.geofence else None,

                )

            )

        return results

    async def upsert_geofence(

        self, user_id: str, class_id: str, data: GeofenceUpsert

    ) -> GeofenceResponse:

        teacher = await self.get_teacher_by_user_id(user_id)

        academic_class = await self.class_repo.get_by_id(class_id)

        if not academic_class:

            raise HTTPException(

                status_code=status.HTTP_404_NOT_FOUND,

                detail="Academic Class not found.",

            )

        if academic_class.teacherId != teacher.id:

            raise HTTPException(

                status_code=status.HTTP_403_FORBIDDEN,

                detail="Access Denied: You do not teach this academic class.",

            )

        geofence = await self.geofence_repo.upsert_geofence(

            class_id=class_id,

            latitude=data.latitude,

            longitude=data.longitude,

            radius=data.radius_meters,

        )

        return GeofenceResponse.model_validate(geofence)

    async def get_session_attendance_roster(

        self, user_id: str, session_id: str

    ) -> SessionAttendanceResponse:

        teacher = await self.get_teacher_by_user_id(user_id)

        session = await db.session.find_unique(

            where={"id": session_id},

            include={"academicClass": True},

        )

        if not session:

            raise HTTPException(

                status_code=status.HTTP_404_NOT_FOUND,

                detail="Attendance Session not found.",

            )

        if session.academicClass.teacherId != teacher.id:

            raise HTTPException(

                status_code=status.HTTP_403_FORBIDDEN,

                detail="Access Denied: You do not teach this academic class.",

            )

        enrollments = await db.enrollment.find_many(

            where={"academicClassId": session.academicClassId},

            include={"student": {"include": {"user": True}}},

        )

        attendance_records = await db.attendance.find_many(

            where={"sessionId": session_id}

        )

        attendance_map = {rec.studentId: rec for rec in attendance_records}

        roster_items: List[StudentRosterItem] = []

        for enroll in enrollments:

            student = enroll.student

            user = student.user

            full_name = self._resolve_full_name(student.firstName, student.lastName)

            if student.id in attendance_map:

                rec = attendance_map[student.id]

                roster_items.append(

                    StudentRosterItem(

                        student_id=student.id,

                        enrollment_number=student.enrollmentNumber,

                        full_name=full_name,

                        email=user.email,

                        status=rec.status,

                        final_score=rec.finalAiScore,

                        marked_at=rec.createdAt,

                    )

                )

            else:

                roster_items.append(

                    StudentRosterItem(

                        student_id=student.id,

                        enrollment_number=student.enrollmentNumber,

                        full_name=full_name,

                        email=user.email,

                        status="Absent",

                        final_score=0.0,

                        marked_at=None,

                    )

                )

        return SessionAttendanceResponse(

            session_id=session_id,

            class_name=session.academicClass.name,

            roster=roster_items,

        )

    async def get_absent_students(

        self, session_id: str, user_id: str

    ) -> List[AbsentStudentItem]:

        teacher = await self.get_teacher_by_user_id(user_id)

        session = await db.session.find_unique(

            where={"id": session_id},

            include={"academicClass": True},

        )

        if not session:

            raise HTTPException(

                status_code=status.HTTP_404_NOT_FOUND,

                detail="Attendance Session not found.",

            )

        if session.academicClass.teacherId != teacher.id:

            raise HTTPException(

                status_code=status.HTTP_403_FORBIDDEN,

                detail="Access Denied: You do not teach this academic class.",

            )

        enrollments = await db.enrollment.find_many(

            where={"academicClassId": session.academicClassId},

            include={"student": {"include": {"user": True}}},

        )

        attendance_records = await db.attendance.find_many(

            where={"sessionId": session_id}

        )

        marked_ids = {rec.studentId for rec in attendance_records}

        absent_items: List[AbsentStudentItem] = []

        for enroll in enrollments:

            student = enroll.student

            if student.id not in marked_ids:

                absent_items.append(

                    AbsentStudentItem(

                        student_id=student.id,

                        enrollment_number=student.enrollmentNumber,

                        full_name=self._resolve_full_name(student.firstName, student.lastName),

                        email=student.user.email if student.user else "",

                    )

                )

        return absent_items

    async def bulk_mark_attendance(

        self, session_id: str, user_id: str, request: BulkMarkRequest

    ) -> int:

        teacher = await self.get_teacher_by_user_id(user_id)

        session = await db.session.find_unique(

            where={"id": session_id},

            include={"academicClass": True},

        )

        if not session:

            raise HTTPException(

                status_code=status.HTTP_404_NOT_FOUND,

                detail="Attendance Session not found.",

            )

        if session.academicClass.teacherId != teacher.id:

            raise HTTPException(

                status_code=status.HTTP_403_FORBIDDEN,

                detail="Access Denied: You do not teach this academic class.",

            )

        count = 0

        for record in request.records:

            await db.attendance.upsert(

                where={

                    "studentId_sessionId": {

                        "studentId": record.student_id,

                        "sessionId": session_id,

                    }

                },

                data={

                    "create": {

                        "studentId": record.student_id,

                        "sessionId": session_id,

                        "status": record.status,

                        "faceScore": 0.0,

                        "livenessScore": 0.0,

                        "backgroundScore": 0.0,

                        "finalAiScore": 0.0,

                        "gpsLatitude": 0.0,

                        "gpsLongitude": 0.0,

                        "remarks": "Manual entry by teacher",

                    },

                    "update": {

                        "status": record.status,

                        "remarks": "Manual entry by teacher",

                    },

                },

            )

            count += 1

        return count

    async def export_class_attendance(

        self,

        class_id: str,

        user_id: str,

        from_date: Optional[datetime],

        to_date: Optional[datetime],

    ) -> List[dict]:

        teacher = await self.get_teacher_by_user_id(user_id)

        academic_class = await self.class_repo.get_by_id(class_id)

        if not academic_class:

            raise HTTPException(

                status_code=status.HTTP_404_NOT_FOUND,

                detail="Academic Class not found.",

            )

        if academic_class.teacherId != teacher.id:

            raise HTTPException(

                status_code=status.HTTP_403_FORBIDDEN,

                detail="Access Denied: You do not teach this academic class.",

            )

        session_where: dict = {"academicClassId": class_id}

        if from_date or to_date:

            start_filter: dict = {}

            if from_date:

                start_filter["gte"] = from_date

            if to_date:

                start_filter["lte"] = to_date

            session_where["startTime"] = start_filter

        sessions = await db.session.find_many(

            where=session_where,

            include={"academicClass": {"include": {"subject": True}}},

            order={"startTime": "asc"},

        )

        rows: List[dict] = []

        for session in sessions:

            subject_name = (

                session.academicClass.subject.name

                if session.academicClass and session.academicClass.subject

                else "—"

            )

            class_name = session.academicClass.name if session.academicClass else "—"

            attendance_records = await db.attendance.find_many(

                where={"sessionId": session.id},

                include={"student": {"include": {"user": True}}},

            )

            for rec in attendance_records:

                student = rec.student

                rows.append(

                    {

                        "enrollment_number": student.enrollmentNumber if student else "",

                        "first_name": student.firstName or "" if student else "",

                        "last_name": student.lastName or "" if student else "",

                        "email": student.user.email if student and student.user else "",

                        "session_date": session.startTime.isoformat(),

                        "class_name": class_name,

                        "subject": subject_name,

                        "status": rec.status,

                        "final_ai_score": rec.finalAiScore,

                        "remarks": rec.remarks or "",

                    }

                )

        return rows

    async def get_class_stats(self, user_id: str, class_id: str) -> ClassStatsResponse:

        teacher = await self.get_teacher_by_user_id(user_id)

        academic_class = await self.class_repo.get_by_id(class_id)

        if not academic_class:

            raise HTTPException(

                status_code=status.HTTP_404_NOT_FOUND,

                detail="Academic Class not found.",

            )

        if academic_class.teacherId != teacher.id:

            raise HTTPException(

                status_code=status.HTTP_403_FORBIDDEN,

                detail="Access Denied: You do not teach this academic class.",

            )

        total_students = await db.enrollment.count(where={"academicClassId": class_id})

        total_sessions = await db.session.count(where={"academicClassId": class_id})

        overall_percentage = 0.0

        history: List[SessionTrendItem] = []

        if total_students > 0 and total_sessions > 0:

            sessions = await db.session.find_many(

                where={"academicClassId": class_id},

                order={"startTime": "asc"},

            )

            session_ids = [s.id for s in sessions]

            present_count = await db.attendance.count(

                where={

                    "sessionId": {"in": session_ids},

                    "status": {"in": ["Present", "Approved"]},

                }

            )

            total_possible_events = total_students * total_sessions

            overall_percentage = round(

                (present_count / total_possible_events) * 100.0, 2

            )

            for index, s in enumerate(sessions):

                p_count = await db.attendance.count(

                    where={

                        "sessionId": s.id,

                        "status": {"in": ["Present", "Approved"]},

                    }

                )

                pct = round((p_count / total_students) * 100.0, 2)

                history.append(

                    SessionTrendItem(

                        session_id=s.id,

                        session_name=f"Session {index + 1}",

                        attendance_percentage=pct,

                    )

                )

        return ClassStatsResponse(

            class_id=class_id,

            total_sessions=total_sessions,

            total_students=total_students,

            overall_attendance_percentage=overall_percentage,

            history=history,

        )

    async def manual_override_attendance(

        self, user_id: str, session_id: str, student_id: str, status_val: str

    ) -> bool:

        teacher = await self.get_teacher_by_user_id(user_id)

        session = await db.session.find_unique(

            where={"id": session_id},

            include={"academicClass": True},

        )

        if not session:

            raise HTTPException(

                status_code=status.HTTP_404_NOT_FOUND,

                detail="Attendance Session not found.",

            )

        if session.academicClass.teacherId != teacher.id:

            raise HTTPException(

                status_code=status.HTTP_403_FORBIDDEN,

                detail="Access Denied: You do not teach this academic class.",

            )

        enrollment = await db.enrollment.find_unique(

            where={

                "studentId_academicClassId": {

                    "studentId": student_id,

                    "academicClassId": session.academicClassId,

                }

            }

        )

        if not enrollment:

            raise HTTPException(

                status_code=status.HTTP_404_NOT_FOUND,

                detail="Student is not enrolled in this class.",

            )

        existing = await db.attendance.find_unique(

            where={

                "studentId_sessionId": {

                    "studentId": student_id,

                    "sessionId": session_id,

                }

            }

        )

        if existing:

            await db.attendance.update(

                where={"id": existing.id},

                data={

                    "status": status_val,

                    "remarks": f"Manual override by Teacher to {status_val}",

                },

            )

        else:

            score = 1.0 if status_val == "Present" else 0.0

            await db.attendance.create(

                data={

                    "studentId": student_id,

                    "sessionId": session_id,

                    "status": status_val,

                    "faceScore": score,

                    "livenessScore": score,

                    "backgroundScore": score,

                    "finalAiScore": score,

                    "gpsLatitude": 0.0,

                    "gpsLongitude": 0.0,

                    "remarks": f"Manual override by Teacher to {status_val}",

                }

            )

        return True

    async def get_teacher_sessions(self, user_id: str) -> List[SessionWithClassResponse]:

        teacher = await self.get_teacher_by_user_id(user_id)

        sessions = await db.session.find_many(

            where={"academicClass": {"teacherId": teacher.id}},

            include={"academicClass": {"include": {"subject": True}}},

            order={"endTime": "desc"},

        )

        results: List[SessionWithClassResponse] = []

        for s in sessions:

            subject_name = (

                s.academicClass.subject.name

                if s.academicClass and s.academicClass.subject

                else "—"

            )

            results.append(

                SessionWithClassResponse(

                    id=s.id,

                    academicClassId=s.academicClassId,

                    class_name=s.academicClass.name,

                    subject=subject_name,

                    startTime=s.startTime,

                    endTime=s.endTime,

                    isActive=s.isActive,

                )

            )

        return results

