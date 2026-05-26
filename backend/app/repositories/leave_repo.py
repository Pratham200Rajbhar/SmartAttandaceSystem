
from app.core.logging_config import get_logger
from datetime import datetime
from typing import List, Optional
from prisma.models import LeaveRequest
from app.db.client import db

logger = get_logger("app.leave_repo")

class LeaveRepository:

    async def create(self, data: dict) -> LeaveRequest:

        return await db.leaverequest.create(data=data)

    async def get_by_id(self, leave_id: str) -> Optional[LeaveRequest]:

        return await db.leaverequest.find_unique(

            where={"id": leave_id},

            include={"student": True}

        )

    async def get_by_student_id(self, student_id: str) -> List[LeaveRequest]:

        return await db.leaverequest.find_many(

            where={"studentId": student_id},

            include={"student": True},

            order={"createdAt": "desc"}

        )

    async def get_pending_for_teacher(self, teacher_id: str) -> List[LeaveRequest]:

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

