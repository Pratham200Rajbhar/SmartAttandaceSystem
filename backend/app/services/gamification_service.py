
import logging

from datetime import datetime, timedelta, timezone

from app.repositories.student_repo import StudentRepository

from app.repositories.attendance_repo import AttendanceRepository

logger = logging.getLogger("app.gamification")

class GamificationService:

    def __init__(self):

        self.student_repo = StudentRepository()

        self.attendance_repo = AttendanceRepository()

    async def update_streak(self, student_id: str, attendance_status: str) -> dict:

        student = await self.student_repo.get_by_id(student_id)

        if not student:

            return {"error": "Student not found"}

        current_streak = student.currentStreak or 0

        highest_streak = student.highestStreak or 0

        if attendance_status in ["Present", "Approved"]:

            new_streak = current_streak + 1

            new_highest = max(new_streak, highest_streak)

            await self.student_repo.update_streak(

                student_id=student_id,

                current_streak=new_streak,

                highest_streak=new_highest

            )

            logger.info(f"🔥 Streak updated for student {student_id}: {new_streak} (highest: {new_highest})")

            return {

                "current_streak": new_streak,

                "highest_streak": new_highest,

                "streak_increased": True

            }

        elif attendance_status == "Absent":

            await self.student_repo.update_streak(

                student_id=student_id,

                current_streak=0,

                highest_streak=highest_streak

            )

            logger.info(f"❌ Streak reset for student {student_id} (was {current_streak})")

            return {

                "current_streak": 0,

                "highest_streak": highest_streak,

                "streak_increased": False,

                "streak_broken": True

            }

        else:

            return {

                "current_streak": current_streak,

                "highest_streak": highest_streak,

                "streak_increased": False

            }

    async def calculate_consecutive_absences(self, student_id: str, days: int = 3) -> int:

        end_date = datetime.now(timezone.utc)

        start_date = end_date - timedelta(days=7)

        records = await self.attendance_repo.get_by_student_in_date_range(

            student_id=student_id,

            start_date=start_date,

            end_date=end_date

        )

        sorted_records = sorted(records, key=lambda r: r.createdAt, reverse=True)

        consecutive_absences = 0

        for record in sorted_records:

            if record.status == "Absent":

                consecutive_absences += 1

            else:

                break

        return consecutive_absences

    async def get_student_stats(self, student_id: str) -> dict:

        student = await self.student_repo.get_by_id(student_id)

        if not student:

            return {}

        all_records = await self.attendance_repo.get_by_student_id(student_id)

        total = len(all_records)

        present = sum(1 for r in all_records if r.status in ["Present", "Approved"])

        absent = sum(1 for r in all_records if r.status == "Absent")

        flagged = sum(1 for r in all_records if r.status == "Flagged")

        excused = sum(1 for r in all_records if r.status == "Excused")

        percentage = (present / total * 100) if total > 0 else 0

        return {

            "current_streak": student.currentStreak or 0,

            "highest_streak": student.highestStreak or 0,

            "total_classes": total,

            "present_count": present,

            "absent_count": absent,

            "flagged_count": flagged,

            "excused_count": excused,

            "attendance_percentage": round(percentage, 2)

        }

