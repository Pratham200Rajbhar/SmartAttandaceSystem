from typing import Optional

from fastapi import HTTPException, status

from app.core.security import hash_password, verify_password, create_access_token
from app.db.client import db
from app.repositories.user_repo import UserRepository
from app.repositories.student_repo import StudentRepository
from app.repositories.teacher_repo import TeacherRepository
from app.schemas.auth import Token, UserLogin
from app.schemas.student import StudentCreate, StudentResponse
from app.schemas.teacher import TeacherCreate, TeacherResponse


class AuthService:
    def __init__(self) -> None:
        self.user_repo = UserRepository()
        self.student_repo = StudentRepository()
        self.teacher_repo = TeacherRepository()

    async def authenticate(self, login_data: UserLogin) -> Optional[Token]:
        user = await self.user_repo.get_by_email(login_data.email)
        if not user or not verify_password(login_data.password, user.hashedPassword):
            return None

        if user.role == "STUDENT":
            student = await self.student_repo.get_by_user_id(user.id)
            if student and login_data.device_uuid:
                if not student.deviceUuid:
                    await db.student.update(
                        where={"id": student.id}, data={"deviceUuid": login_data.device_uuid}
                    )
                elif student.deviceUuid != login_data.device_uuid:
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail="Account is bound to another device.",
                    )

        token = create_access_token(subject=user.id, role=user.role)
        return Token(access_token=token, token_type="bearer", role=user.role)

    async def register_student(self, data: StudentCreate) -> Optional[StudentResponse]:
        if await self.user_repo.get_by_email(data.email):
            return None
        hashed = hash_password(data.password)
        user = await self.user_repo.create(email=data.email, password_hash=hashed, role="STUDENT")
        student = await self.student_repo.create(user_id=user.id, enrollment=data.enrollment_number)
        return StudentResponse(id=student.id, user_id=user.id, enrollment_number=student.enrollmentNumber, email=user.email)

    async def register_teacher(self, data: TeacherCreate) -> Optional[TeacherResponse]:
        if await self.user_repo.get_by_email(data.email):
            return None
        hashed = hash_password(data.password)
        user = await self.user_repo.create(email=data.email, password_hash=hashed, role="TEACHER")
        teacher = await self.teacher_repo.create(user_id=user.id, department=data.department_id, designation=data.designation_id)
        return TeacherResponse(id=teacher.id, user_id=user.id, department=teacher.department, designation=teacher.designation, email=user.email)
