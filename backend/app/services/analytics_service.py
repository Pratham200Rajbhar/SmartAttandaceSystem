
from app.core.logging_config import get_logger
from datetime import datetime, timedelta, timezone
from typing import List, Dict
from app.repositories.student_repo import StudentRepository
from app.repositories.attendance_repo import AttendanceRepository
from app.services.gamification_service import GamificationService

logger = get_logger("app.analytics")

class AnalyticsService:

    def __init__(self):

        self.student_repo = StudentRepository()

        self.attendance_repo = AttendanceRepository()

        self.gamification_service = GamificationService()

    async def detect_at_risk_students(self) -> List[Dict]:

        at_risk_students = []

        all_students = await self.student_repo.get_all_active()

        for student in all_students:

            risk_factors = []

            all_records = await self.attendance_repo.get_by_student_id(student.id)

            if len(all_records) < 5:

                continue

            total = len(all_records)

            present = sum(1 for r in all_records if r.status in ["Present", "Approved"])

            overall_pct = (present / total * 100) if total > 0 else 0

            if overall_pct < 75:

                risk_factors.append(f"Overall attendance {overall_pct:.1f}% (below 75%)")

            recent_pct = await self._calculate_recent_attendance(student.id, days=14)

            historical_pct = await self._calculate_historical_attendance(student.id, days=60)

            if historical_pct > 0 and (historical_pct - recent_pct) > 20:

                risk_factors.append(f"Attendance dropped {historical_pct - recent_pct:.1f}% in last 2 weeks")

            consecutive = await self.gamification_service.calculate_consecutive_absences(student.id)

            if consecutive >= 3:

                risk_factors.append(f"{consecutive} consecutive absences")

            if risk_factors:

                at_risk_students.append({

                    "student_id": student.id,

                    "enrollment_number": student.enrollmentNumber,

                    "name": f"{student.firstName or ''} {student.lastName or ''}".strip(),

                    "overall_percentage": round(overall_pct, 2),

                    "recent_percentage": round(recent_pct, 2),

                    "consecutive_absences": consecutive,

                    "risk_factors": risk_factors,

                    "risk_level": self._calculate_risk_level(len(risk_factors), overall_pct)

                })

        logger.info(f"🚨 Detected {len(at_risk_students)} at-risk students")

        return at_risk_students

    async def _calculate_recent_attendance(self, student_id: str, days: int) -> float:

        end_date = datetime.now(timezone.utc)

        start_date = end_date - timedelta(days=days)

        records = await self.attendance_repo.get_by_student_in_date_range(

            student_id=student_id,

            start_date=start_date,

            end_date=end_date

        )

        if not records:

            return 0.0

        present = sum(1 for r in records if r.status in ["Present", "Approved"])

        return (present / len(records) * 100)

    async def _calculate_historical_attendance(self, student_id: str, days: int) -> float:

        end_date = datetime.now(timezone.utc) - timedelta(days=14)

        start_date = end_date - timedelta(days=days)

        records = await self.attendance_repo.get_by_student_in_date_range(

            student_id=student_id,

            start_date=start_date,

            end_date=end_date

        )

        if not records:

            return 0.0

        present = sum(1 for r in records if r.status in ["Present", "Approved"])

        return (present / len(records) * 100)

    def _calculate_risk_level(self, factor_count: int, overall_pct: float) -> str:

        if overall_pct < 60 or factor_count >= 3:

            return "HIGH"

        elif overall_pct < 70 or factor_count >= 2:

            return "MEDIUM"

        else:

            return "LOW"

    async def get_class_analytics(self, class_id: str) -> Dict:

        from app.repositories.session_repo import SessionRepository

        session_repo = SessionRepository()

        sessions = await session_repo.get_by_class_id(class_id)

        total_sessions = len(sessions)

        session_ids = [s.id for s in sessions]

        all_attendance = []

        for session_id in session_ids:

            records = await self.attendance_repo.get_by_session_id(session_id)

            all_attendance.extend(records)

        if not all_attendance:

            return {

                "total_sessions": total_sessions,

                "total_attendance_records": 0,

                "average_attendance_rate": 0,

                "status_breakdown": {}

            }

        total_records = len(all_attendance)

        present = sum(1 for r in all_attendance if r.status in ["Present", "Approved"])

        absent = sum(1 for r in all_attendance if r.status == "Absent")

        flagged = sum(1 for r in all_attendance if r.status == "Flagged")

        excused = sum(1 for r in all_attendance if r.status == "Excused")

        avg_rate = (present / total_records * 100) if total_records > 0 else 0

        return {

            "total_sessions": total_sessions,

            "total_attendance_records": total_records,

            "average_attendance_rate": round(avg_rate, 2),

            "status_breakdown": {

                "present": present,

                "absent": absent,

                "flagged": flagged,

                "excused": excused

            }

        }

