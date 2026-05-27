from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from prisma.models import User, Student, Teacher

from app.core.logging_config import get_logger
from app.core.security import decode_access_token
from app.repositories.user_repo import UserRepository
from app.repositories.student_repo import StudentRepository
from app.repositories.teacher_repo import TeacherRepository

logger = get_logger("app.auth")

reusable_oauth2 = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")

_UNAUTHORIZED = HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)
_FORBIDDEN = {"STUDENT": "Access forbidden: Students only", "TEACHER": "Access forbidden: Teachers only"}
_INACTIVE = "User account is inactive or disabled"


async def _check_token_revoked(token: str) -> None:
    try:
        from app.db.redis import get_redis
        if await get_redis().get(f"denylist:{token}"):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token has been revoked",
                headers={"WWW-Authenticate": "Bearer"},
            )
    except HTTPException:
        raise
    except Exception:
        pass


async def _validate_token_payload(token: str) -> dict:
    await _check_token_revoked(token)
    payload = decode_access_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Subject not found in token",
        )
    return payload


async def get_current_user(token: str = Depends(reusable_oauth2)) -> User:
    payload = await _validate_token_payload(token)
    user_id = payload.get("sub")
    user = await UserRepository().get_by_id(user_id)
    if not user or not user.isActive:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=_INACTIVE,
        )
    return user


async def get_current_student(current_user: User = Depends(get_current_user)) -> Student:
    if current_user.role != "STUDENT":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=_FORBIDDEN["STUDENT"])
    student = await StudentRepository().get_by_user_id(current_user.id)
    if not student:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student profile not found")
    return student


async def get_current_teacher(current_user: User = Depends(get_current_user)) -> Teacher:
    if current_user.role != "TEACHER":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=_FORBIDDEN["TEACHER"])
    teacher = await TeacherRepository().get_by_user_id(current_user.id)
    if not teacher:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Teacher profile not found")
    return teacher


class RoleChecker:
    def __init__(self, allowed_roles: list[str]) -> None:
        self.allowed_roles = allowed_roles

    def __call__(self, current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in self.allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied: Insufficient permissions",
            )
        return current_user


async def get_current_user_from_token(token: str) -> User:
    await _check_token_revoked(token)
    payload = decode_access_token(token)
    if not payload:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Could not validate credentials")
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Subject not found in token")
    user = await UserRepository().get_by_id(user_id)
    if not user or not user.isActive:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=_INACTIVE)
    return user

