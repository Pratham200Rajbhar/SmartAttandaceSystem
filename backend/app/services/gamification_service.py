from datetime import datetime, timedelta, timezone

from app.core.logging_config import get_logger
from app.repositories.student_repo import StudentRepository
from app.repositories.attendance_repo import AttendanceRepository

logger = get_logger("app.gamification")


class GamificationService:
    def __init__(self):
        self.student_repo = StudentRepository()
        self.attendance_repo = AttendanceRepository()

    async def update_streak(self, student_id: str, attendance_status: str) -> dict:
        student = await self.student_repo.get_by_id(student_id)
        if not student:
            return {"error": "Student not found"}

        current = student.currentStreak or 0
        highest = student.highestStreak or 0

        if attendance_status in ("Present", "Approved"):
            new_streak = current + 1
            new_highest = max(new_streak, highest)
            await self.student_repo.update_streak(student_id, new_streak, new_highest)
            return {"current_streak": new_streak, "highest_streak": new_highest, "streak_increased": True}
        elif attendance_status == "Absent":
            await self.student_repo.update_streak(student_id, 0, highest)
            return {"current_streak": 0, "highest_streak": highest, "streak_increased": False, "streak_broken": True}
        else:
            return {"current_streak": current, "highest_streak": highest, "streak_increased": False}

    async def calculate_consecutive_absences(self, student_id: str, days: int = 3) -> int:
        end = datetime.now(timezone.utc)
        records = await self.attendance_repo.get_by_student_in_date_range(
            student_id=student_id, start_date=end - timedelta(days=7), end_date=end
        )
        consecutive = 0
        for record in sorted(records, key=lambda r: r.createdAt, reverse=True):
            if record.status == "Absent":
                consecutive += 1
            else:
                break
        return consecutive

    async def get_student_stats(self, student_id: str) -> dict:
        student = await self.student_repo.get_by_id(student_id)
        if not student:
            return {}

        all_records = await self.attendance_repo.get_by_student_id(student_id)
        total = len(all_records)
        present = sum(1 for r in all_records if r.status in ("Present", "Approved"))
        absent = sum(1 for r in all_records if r.status == "Absent")
        flagged = sum(1 for r in all_records if r.status == "Flagged")
        excused = sum(1 for r in all_records if r.status == "Excused")

        return {
            "current_streak": student.currentStreak or 0,
            "highest_streak": student.highestStreak or 0,
            "total_classes": total,
            "present_count": present,
            "absent_count": absent,
            "flagged_count": flagged,
            "excused_count": excused,
            "attendance_percentage": round((present / total * 100) if total > 0 else 0, 2),
        }
