
import logging

from datetime import datetime

from typing import Optional

from app.repositories.leave_repo import LeaveRepository

from app.repositories.attendance_repo import AttendanceRepository

from app.repositories.enrollment_repo import EnrollmentRepository

from app.repositories.session_repo import SessionRepository

from prisma.models import LeaveRequest

logger = logging.getLogger("app.leave_service")

class LeaveService:

    def __init__(self):

        self.leave_repo = LeaveRepository()

        self.attendance_repo = AttendanceRepository()

        self.enrollment_repo = EnrollmentRepository()

        self.session_repo = SessionRepository()

    async def approve_leave(

        self, 

        leave_id: str, 

        teacher_id: str, 

        status: str, 

        approver_note: Optional[str] = None

    ) -> Optional[LeaveRequest]:

        leave = await self.leave_repo.get_by_id(leave_id)

        if not leave:

            return None

        updated_leave = await self.leave_repo.update_status(

            leave_id=leave_id,

            status=status,

            approved_by=teacher_id,

            approver_note=approver_note

        )

        if status == "APPROVED":

            await self._mark_excused_attendance(leave)

            logger.info(f"✅ Leave approved for student {leave.studentId} from {leave.startDate} to {leave.endDate}")

        return updated_leave

    async def _mark_excused_attendance(self, leave: LeaveRequest):

        sessions = await self.session_repo.get_sessions_in_date_range(

            start_date=leave.startDate,

            end_date=leave.endDate

        )

        enrollments = await self.enrollment_repo.get_by_student_id(leave.studentId)

        enrolled_class_ids = [e.academicClassId for e in enrollments]

        relevant_sessions = [s for s in sessions if s.academicClassId in enrolled_class_ids]

        for session in relevant_sessions:

            existing = await self.attendance_repo.get_by_student_and_session(

                student_id=leave.studentId,

                session_id=session.id

            )

            if existing:

                await self.attendance_repo.update(

                    attendance_id=existing.id,

                    data={

                        "status": "Excused",

                        "remarks": f"Approved leave: {leave.reason}"

                    }

                )

                logger.info(f"Updated attendance {existing.id} to Excused")

            else:

                await self.attendance_repo.create({

                    "studentId": leave.studentId,

                    "sessionId": session.id,

                    "status": "Excused",

                    "faceScore": 0.0,

                    "livenessScore": 0.0,

                    "backgroundScore": 0.0,

                    "finalAiScore": 0.0,

                    "gpsLatitude": 0.0,

                    "gpsLongitude": 0.0,

                    "remarks": f"Approved leave: {leave.reason}"

                })

                logger.info(f"Created excused attendance for session {session.id}")

    async def check_leave_conflict(

        self, 

        student_id: str, 

        start_date: datetime, 

        end_date: datetime

    ) -> bool:

        overlapping_leaves = await self.leave_repo.get_approved_leaves_in_range(

            student_id=student_id,

            start_date=start_date,

            end_date=end_date

        )

        return len(overlapping_leaves) > 0

