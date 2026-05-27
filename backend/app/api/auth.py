from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Request, status
from prisma.models import User

from app.api.dependencies import get_current_user, reusable_oauth2
from app.core.config import settings
from app.core.logging_config import get_logger
from app.core.security import decode_access_token
from app.db.client import db
from app.db.redis import get_redis
from app.repositories.student_repo import StudentRepository
from app.schemas.auth import Token, UserLogin, UserProfileResponse, DeviceChangeRequestCreate
from app.schemas.student import StudentCreate, StudentResponse
from app.schemas.teacher import TeacherCreate, TeacherResponse
from app.services.auth_service import AuthService
from app.services.device_change_service import DeviceChangeService

logger = get_logger("app.api.auth")

router = APIRouter(prefix="/auth", tags=["Authentication"])

_RATE_LIMIT_WINDOW = 60
_RATE_LIMIT_MAX = 10


async def _rate_limit(request: Request) -> None:
    if settings.ENVIRONMENT == "development":
        return
    forwarded = request.headers.get("X-Forwarded-For")
    ip = forwarded.split(",")[0].strip() if forwarded else (request.client.host if request.client else "unknown")
    key = f"ratelimit:auth:{ip}"
    r = await get_redis()
    count = await r.incr(key)
    if count == 1:
        await r.expire(key, _RATE_LIMIT_WINDOW)
    if count > _RATE_LIMIT_MAX:
        raise HTTPException(status_code=status.HTTP_429_TOO_MANY_REQUESTS, detail="Too many requests. Please try again later.")


@router.post("/login", response_model=Token)
async def login(login_data: UserLogin, request: Request, auth_service: AuthService = Depends()) -> Token:
    await _rate_limit(request)
    token = await auth_service.authenticate(login_data)
    if not token:
        logger.warning("Failed login: %s", login_data.email)
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect email or password")
    return token


@router.post("/register/student", response_model=StudentResponse, status_code=status.HTTP_201_CREATED)
async def register_student(data: StudentCreate, request: Request, auth_service: AuthService = Depends()) -> StudentResponse:
    await _rate_limit(request)
    student = await auth_service.register_student(data)
    if not student:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User with this email is already registered")
    return student


@router.post("/register/teacher", response_model=TeacherResponse, status_code=status.HTTP_201_CREATED)
async def register_teacher(data: TeacherCreate, request: Request, auth_service: AuthService = Depends()) -> TeacherResponse:
    await _rate_limit(request)
    teacher = await auth_service.register_teacher(data)
    if not teacher:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User with this email is already registered")
    return teacher


@router.get("/me", response_model=UserProfileResponse)
async def get_me(current_user: User = Depends(get_current_user)) -> UserProfileResponse:
    student_profile = None
    teacher_profile = None

    if current_user.role == "STUDENT":
        student = await db.student.find_unique(where={"userId": current_user.id})
        if student:
            embedding = await StudentRepository().get_face_embedding(student.id)
            student_profile = {
                "id": student.id,
                "enrollment_number": student.enrollmentNumber,
                "first_name": student.firstName,
                "last_name": student.lastName,
                "face_registered": embedding is not None and len(embedding) > 0,
            }
    elif current_user.role == "TEACHER":
        teacher = await db.teacher.find_unique(where={"userId": current_user.id})
        if teacher:
            teacher_profile = {
                "id": teacher.id,
                "department": teacher.department.name if teacher.department else "",
                "designation": teacher.designation.name if teacher.designation else "",
                "employee_id": teacher.employeeId,
                "first_name": teacher.firstName,
                "last_name": teacher.lastName,
            }

    return UserProfileResponse(
        id=current_user.id,
        email=current_user.email,
        role=current_user.role,
        is_active=current_user.isActive,
        student_profile=student_profile,
        teacher_profile=teacher_profile,
    )



@router.post("/logout", status_code=status.HTTP_200_OK)
async def logout(token: str = Depends(reusable_oauth2)) -> dict:
    payload = decode_access_token(token)
    if payload:
        exp = payload.get("exp")
        if exp:
            ttl = exp - int(datetime.now(timezone.utc).timestamp())
            if ttl > 0:
                try:
                    await get_redis().setex(f"denylist:{token}", ttl, "revoked")
                    logger.info("Token revoked: user=%s", payload.get("sub"))
                except Exception as cache_err:
                    logger.warning("Failed to add token to Redis denylist: %s", cache_err)
    return {"status": "success", "message": "Successfully logged out."}
@router.post("/request-device-change", status_code=status.HTTP_200_OK)
async def request_device_change(
    data: DeviceChangeRequestCreate,
    request: Request,
    device_change_service: DeviceChangeService = Depends(),
) -> dict:
    await _rate_limit(request)
    await device_change_service.request_device_change(data)
    return {"status": "success", "message": "Device change request submitted successfully."}


# --- System Config (Public) ---
from app.schemas.system_config import SystemConfigResponse
from app.services.system_config_service import SystemConfigService

@router.get("/config", response_model=SystemConfigResponse)
async def get_public_system_config(config_service: SystemConfigService = Depends()):
    return await config_service.get_config()

