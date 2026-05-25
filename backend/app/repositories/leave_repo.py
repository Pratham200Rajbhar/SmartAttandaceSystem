"""
Repository for leave request database operations.
"""
import logging
from datetime import datetime
from typing import List, Optional
from prisma import Prisma
from prisma.models import LeaveRequest
from app.db.client import db

logger = logging.getLogger("app.leave_repo")


class LeaveRepository:
    """Handles CRUD operations for leave requests."""
    
    async def create(self, data: dict) -> LeaveRequest:
        """Create a new leave request."""
        return await db.leaverequest.create(data=data)
    
    async def get_by_id(self, leave_id: str) -> Optional[LeaveRequest]:
        """Get leave request by ID with student details."""
        return await db.leaverequest.find_unique(
            where={"id": leave_id},
            include={"student": True}
        )
    
    async def get_by_student_id(self, student_id: str) -> List[LeaveRequest]:
        """Get all leave requests for a student."""
        return await db.leaverequest.find_many(
            where={"studentId": student_id},
            include={"student": True},
            order={"createdAt": "desc"}
        )
    
    async def get_pending_for_teacher(self, teacher_id: str) -> List[LeaveRequest]:
        """Get pending leave requests for students in teacher's classes."""
        # Get all students enrolled in teacher's classes
        enrollments = await db.enrollment.find_many(
            where={
                "academicClass": {
                    "is": {"teacherId": teacher_id}
                }
            },
            include={"student": True}
        )
        
        student_ids = [e.studentId for e in enrollments]
        
        return await db.leaverequest.find_many(
            where={
                "studentId": {"in": student_ids},
                "status": "PENDING"
            },
            include={"student": True},
            order={"createdAt": "asc"}
        )
    
    async def update_status(
        self, 
        leave_id: str, 
        status: str, 
        approved_by: str, 
        approver_note: Optional[str] = None
    ) -> Optional[LeaveRequest]:
        """Update leave request status."""
        return await db.leaverequest.update(
            where={"id": leave_id},
            data={
                "status": status,
                "approvedBy": approved_by,
                "approverNote": approver_note,
                "updatedAt": datetime.utcnow()
            }
        )
    
    async def get_approved_leaves_in_range(
        self, 
        student_id: str, 
        start_date: datetime, 
        end_date: datetime
    ) -> List[LeaveRequest]:
        """Get approved leaves that overlap with a date range."""
        return await db.leaverequest.find_many(
            where={
                "studentId": student_id,
                "status": "APPROVED",
                "OR": [
                    {
                        "AND": [
                            {"startDate": {"lte": end_date}},
                            {"endDate": {"gte": start_date}}
                        ]
                    }
                ]
            }
        )
