from datetime import datetime, timedelta, timezone
from typing import Tuple

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
            await self._update_redis_score(student_id, new_streak, new_highest)
            return {"current_streak": new_streak, "highest_streak": new_highest, "streak_increased": True}
        elif attendance_status == "Absent":
            await self.student_repo.update_streak(student_id, 0, highest)
            await self._update_redis_score(student_id, 0, highest)
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

    def _get_redis_client(self):
        """Return the active Redis client if available."""
        try:
            from app.db.redis import get_redis
            return get_redis()
        except Exception as e:
            logger.warning("Redis client not available: %s", e)
            return None

    async def _update_redis_score(self, student_id: str, current_streak: int, highest_streak: int) -> None:
        """Update a student's score in the Redis leaderboard."""
        try:
            redis = self._get_redis_client()
            if redis:
                all_records = await self.attendance_repo.get_by_student_id(student_id)
                present_count = sum(1 for r in all_records if r.status in ("Present", "Approved"))
                new_points = present_count * 50 + highest_streak * 100 + current_streak * 20
                await redis.zadd("leaderboard:points", {student_id: float(new_points)})
        except Exception as e:
            logger.warning("Failed to update leaderboard cache: %s", e)

    async def get_leaderboard(self, current_student_id: str) -> dict:
        """Fetch the leaderboard from Redis, falling back to DB if empty."""
        redis = self._get_redis_client()
        cache_key = "leaderboard:points"
        
        try:
            if redis and not await redis.exists(cache_key):
                await self._rebuild_leaderboard_cache(redis, cache_key)
        except Exception as e:
            logger.warning("Redis operation failed in leaderboard check: %s", e)

        leaderboard_data = []
        if redis:
            leaderboard_data = await self._fetch_leaderboard_from_cache(redis, cache_key)

        if not leaderboard_data:
            return await self._get_leaderboard_from_db(current_student_id)

        user_rank, user_points = await self._fetch_user_rank_and_points(redis, cache_key, current_student_id)
        return {
            "leaderboard": leaderboard_data,
            "user_rank": user_rank,
            "user_points": user_points
        }

    async def _rebuild_leaderboard_cache(self, redis, cache_key: str) -> None:
        """Rebuild the leaderboard cache from DB data."""
        if not redis:
            return
        try:
            from app.db.client import db
            students = await db.student.find_many(
                where={"user": {"is": {"isActive": True}}},
                include={"attendance": True}
            )
            scores_dict = {}
            for s in students:
                present_count = sum(1 for r in s.attendance if r.status in ("Present", "Approved"))
                points = present_count * 50 + (s.highestStreak or 0) * 100 + (s.currentStreak or 0) * 20
                scores_dict[s.id] = float(points)
            if scores_dict:
                await redis.zadd(cache_key, scores_dict)
                await redis.expire(cache_key, 3600)
        except Exception as e:
            logger.error("Failed to rebuild leaderboard cache: %s", e, exc_info=True)

    async def _fetch_leaderboard_from_cache(self, redis, cache_key: str) -> list:
        """Fetch top 10 students from Redis cache and load details from DB."""
        try:
            top_members = await redis.zrevrange(cache_key, 0, 9, withscores=True)
            if not top_members:
                return []
            top_ids = [m[0] for m in top_members]
            from app.db.client import db
            top_students = await db.student.find_many(where={"id": {"in": top_ids}})
            students_map = {s.id: s for s in top_students}
            
            leaderboard_data = []
            for s_id, score in top_members:
                s = students_map.get(s_id)
                if s:
                    name = f"{s.firstName or ''} {s.lastName or ''}".strip() or "Student"
                    leaderboard_data.append({
                        "student_id": s_id,
                        "name": name,
                        "points": int(score),
                        "current_streak": s.currentStreak or 0,
                    })
            return leaderboard_data
        except Exception as e:
            logger.error("Failed to fetch leaderboard from cache: %s", e, exc_info=True)
            return []

    async def _fetch_user_rank_and_points(self, redis, cache_key: str, student_id: str) -> Tuple[int | None, int]:
        """Fetch rank and points for a specific user from Redis."""
        if not redis:
            return None, 0
        try:
            current_rank_0 = await redis.zrevrank(cache_key, student_id)
            user_rank = current_rank_0 + 1 if current_rank_0 is not None else None
            current_score = await redis.zscore(cache_key, student_id)
            user_points = int(current_score) if current_score is not None else 0
            return user_rank, user_points
        except Exception as e:
            logger.warning("Failed to fetch user rank from Redis: %s", e)
            return None, 0

    async def _get_leaderboard_from_db(self, current_student_id: str) -> dict:
        """Generate leaderboard directly from database query (fallback)."""
        try:
            from app.db.client import db
            students = await db.student.find_many(
                where={"user": {"is": {"isActive": True}}},
                include={"attendance": True}
            )
            student_list = []
            for s in students:
                present_count = sum(1 for r in s.attendance if r.status in ("Present", "Approved"))
                points = present_count * 50 + (s.highestStreak or 0) * 100 + (s.currentStreak or 0) * 20
                student_list.append((s, points))
            
            student_list.sort(key=lambda x: x[1], reverse=True)
            
            leaderboard_data = []
            for s, points in student_list[:10]:
                name = f"{s.firstName or ''} {s.lastName or ''}".strip() or "Student"
                leaderboard_data.append({
                    "student_id": s.id,
                    "name": name,
                    "points": points,
                    "current_streak": s.currentStreak or 0,
                })
            
            user_rank = None
            user_points = 0
            for index, (s, points) in enumerate(student_list):
                if s.id == current_student_id:
                    user_rank = index + 1
                    user_points = points
                    break
            return {
                "leaderboard": leaderboard_data,
                "user_rank": user_rank,
                "user_points": user_points
            }
        except Exception as e:
            logger.error("Database fallback leaderboard query failed: %s", e, exc_info=True)
            return {"leaderboard": [], "user_rank": None, "user_points": 0}
