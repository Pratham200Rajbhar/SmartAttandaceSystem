from typing import List
from fastapi import HTTPException, status
from app.db.client import db
from app.core.security import verify_password
from app.repositories.user_repo import UserRepository
from app.repositories.student_repo import StudentRepository
from app.schemas.auth import DeviceChangeRequestCreate
from app.schemas.teacher import DeviceChangeResponse

class DeviceChangeService:
    def __init__(self) -> None:
        self.user_repo = UserRepository()
        self.student_repo = StudentRepository()

    async def request_device_change(self, data: DeviceChangeRequestCreate) -> None:
        user = await self.user_repo.get_by_email(data.email)
        if not user or not verify_password(data.password, user.hashedPassword) or user.role != "STUDENT":
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")
        
        student = await self.student_repo.get_by_user_id(user.id)
        if not student:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student record not found")

        # Check if already has pending request
        pending_request = await db.devicechangerequest.find_first(
            where={
                "studentId": student.id,
                "status": "PENDING"
            }
        )

        if pending_request:
            # Update existing pending request
            await db.devicechangerequest.update(
                where={"id": pending_request.id},
                data={
                    "newDeviceUuid": data.new_device_uuid,
                    "reason": data.reason
                }
            )
        else:
            # Create new request
            await db.devicechangerequest.create(
                data={
                    "studentId": student.id,
                    "newDeviceUuid": data.new_device_uuid,
                    "reason": data.reason,
                    "status": "PENDING"
                }
            )

    async def get_pending_requests(self, teacher_id: str) -> List[DeviceChangeResponse]:
        # For simplicity, returning all pending requests in the system.
        # Ideally, we would filter by department or class.
        records = await db.devicechangerequest.find_many(
            where={"status": "PENDING"},
            include={
                "student": {
                    "include": {
                        "user": True
                    }
                }
            },
            order={"createdAt": "desc"}
        )

        response_list = []
        for r in records:
            name = f"{r.student.firstName or ''} {r.student.lastName or ''}".strip()
            response_list.append(DeviceChangeResponse(
                id=r.id,
                student_id=r.studentId,
                student_name=name or "Unknown",
                enrollment_number=r.student.enrollmentNumber,
                new_device_uuid=r.newDeviceUuid,
                reason=r.reason,
                status=r.status,
                approved_by=r.approvedBy,
                created_at=r.createdAt,
                updated_at=r.updatedAt
            ))
        return response_list

    async def approve_request(self, request_id: str, teacher_id: str, new_status: str) -> bool:
        request_record = await db.devicechangerequest.find_unique(where={"id": request_id})
        if not request_record or request_record.status != "PENDING":
            return False

        if new_status == "APPROVED":
            # Update student device_uuid
            await db.student.update(
                where={"id": request_record.studentId},
                data={"deviceUuid": request_record.newDeviceUuid}
            )

        # Update request status
        await db.devicechangerequest.update(
            where={"id": request_id},
            data={
                "status": new_status,
                "approvedBy": teacher_id
            }
        )

        return True
