import logging
from typing import Optional, List
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from app.core.security import decode_access_token
from app.repositories.user_repo import UserRepository
from app.repositories.student_repo import StudentRepository
from app.repositories.teacher_repo import TeacherRepository
from prisma.models import User, Student, Teacher

logger = logging.getLogger("app.auth")


reusable_oauth2 = OAuth2PasswordBearer(
    tokenUrl="/api/v1/auth/login"
)


async def get_current_user(
    token: str = Depends(reusable_oauth2)
) -> User:




    try:
        from app.db.redis import get_redis
        redis_client = get_redis()
        is_revoked = await redis_client.get(f"denylist:{token}")
        if is_revoked:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token has been revoked",
                headers={"WWW-Authenticate": "Bearer"},
            )
    except HTTPException:
        raise
    except Exception as cache_err:
        logger.warning(f"⚠️ Redis Denylist verification bypassed: {cache_err}")

    payload = decode_access_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
        
    user_id: Optional[str] = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Subject not found in token",
        )
        
    user = await UserRepository().get_by_id(user_id)
    if not user or not user.isActive:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User account is inactive or disabled",
        )
    return user


async def get_current_student(
    current_user: User = Depends(get_current_user)
) -> Student:


    if current_user.role != "STUDENT":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access forbidden: Students only",
        )
        
    student = await StudentRepository().get_by_user_id(current_user.id)
    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Student profile not found",
        )
    return student


async def get_current_teacher(
    current_user: User = Depends(get_current_user)
) -> Teacher:


    if current_user.role != "TEACHER":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access forbidden: Teachers only",
        )
        
    teacher = await TeacherRepository().get_by_user_id(current_user.id)
    if not teacher:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Teacher profile not found",
        )
    return teacher


class RoleChecker:


    def __init__(self, allowed_roles: List[str]) -> None:
        self.allowed_roles = allowed_roles

    def __call__(self, current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in self.allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied: Insufficient permissions",
            )
        return current_user


async def get_current_user_from_token(token: str) -> User:
    """
    Authenticate user from raw JWT token (for WebSocket connections).
    Does not use OAuth2PasswordBearer dependency.
    """
    try:
        from app.db.redis import get_redis
        redis_client = get_redis()
        is_revoked = await redis_client.get(f"denylist:{token}")
        if is_revoked:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token has been revoked",
            )
    except HTTPException:
        raise
    except Exception as cache_err:
        logger.warning(f"⚠️ Redis Denylist verification bypassed: {cache_err}")

    payload = decode_access_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
        )
        
    user_id: Optional[str] = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Subject not found in token",
        )
        
    user = await UserRepository().get_by_id(user_id)
    if not user or not user.isActive:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User account is inactive or disabled",
        )
    return user
