from fastapi import APIRouter, Depends, HTTPException, status

from app.schemas.auth import Token, UserLogin, UserProfileResponse
from app.schemas.student import StudentCreate, StudentResponse
from app.schemas.teacher import TeacherCreate, TeacherResponse
from app.services.auth_service import AuthService
from app.api.dependencies import get_current_user, reusable_oauth2
from app.core.logging_config import get_logger
from app.core.security import decode_access_token
from app.db.client import db
from app.db.redis import get_redis
from prisma.models import User

logger = get_logger("app.api.auth")

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/login", response_model=Token)
async def login(
    login_data: UserLogin,
    auth_service: AuthService = Depends(),
) -> Token:
    token = await auth_service.authenticate(login_data)
    if not token:
        logger.warning("Failed login: %s", login_data.email)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )
    return token

@router.post(

    "/register/student",

    response_model=StudentResponse,

    status_code=status.HTTP_201_CREATED

)

async def register_student(

    data: StudentCreate,

    auth_service: AuthService = Depends()

) -> StudentResponse:

    student = await auth_service.register_student(data)

    if not student:

        raise HTTPException(

            status_code=status.HTTP_400_BAD_REQUEST,

            detail="User with this email is already registered",

        )

    return student

@router.post(

    "/register/teacher",

    response_model=TeacherResponse,

    status_code=status.HTTP_201_CREATED

)

async def register_teacher(

    data: TeacherCreate,

    auth_service: AuthService = Depends()

) -> TeacherResponse:

    teacher = await auth_service.register_teacher(data)

    if not teacher:

        raise HTTPException(

            status_code=status.HTTP_400_BAD_REQUEST,

            detail="User with this email is already registered",

        )

    return teacher

@router.get("/me", response_model=UserProfileResponse)

async def get_me(

    current_user: User = Depends(get_current_user)

) -> UserProfileResponse:

    student_profile = None

    teacher_profile = None

    if current_user.role == "STUDENT":

        student = await db.student.find_unique(where={"userId": current_user.id})

        if student:

            from app.repositories.student_repo import StudentRepository

            student_repo = StudentRepository()

            embedding = await student_repo.get_face_embedding(student.id)

            face_registered = embedding is not None and len(embedding) > 0

            student_profile = {

                "id": student.id,

                "enrollment_number": student.enrollmentNumber,

                "first_name": student.firstName,

                "last_name": student.lastName,

                "face_registered": face_registered,

            }

    elif current_user.role == "TEACHER":

        teacher = await db.teacher.find_unique(where={"userId": current_user.id})

        if teacher:

            teacher_profile = {

                "id": teacher.id,

                "department": teacher.department,

                "designation": teacher.designation,

            }

    return UserProfileResponse(

        id=current_user.id,

        email=current_user.email,

        role=current_user.role,

        is_active=current_user.isActive,

        student_profile=student_profile,

        teacher_profile=teacher_profile,

    )

@router.post("/request-device-reset", status_code=status.HTTP_200_OK)
async def request_device_reset(
    current_user: User = Depends(get_current_user),
) -> dict:
    if current_user.role != "STUDENT":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only students can request device resets",
        )
    await db.student.update(
        where={"userId": current_user.id},
        data={"deviceResetRequested": True},
    )
    logger.info("Device reset requested: %s", current_user.email)
    return {"status": "success", "message": "Device reset request recorded successfully"}

@router.post("/logout", status_code=status.HTTP_200_OK)
async def logout(
    token: str = Depends(reusable_oauth2),
) -> dict:
    from datetime import datetime, timezone
    payload = decode_access_token(token)
    if payload:
        exp = payload.get("exp")
        if exp:
            now = int(datetime.now(timezone.utc).timestamp())
            ttl = exp - now
            if ttl > 0:
                try:
                    redis_client = get_redis()
                    await redis_client.setex(f"denylist:{token}", ttl, "revoked")
                    logger.info("Token revoked: user=%s", payload.get("sub"))
                except Exception as cache_err:
                    logger.warning("Failed to add token to Redis denylist: %s", cache_err)
    return {"status": "success", "message": "Successfully logged out."}

