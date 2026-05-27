import os
import uuid
import shutil
from datetime import datetime, timezone, date, timedelta

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, status
from prisma.models import Student

from app.api.dependencies import get_current_student
from app.core.config import settings
from app.core.logging_config import get_logger
from app.core.security import create_access_token
from app.db.client import db
from app.repositories.leave_repo import LeaveRepository

from app.schemas.attendance import AttendanceMarkResponse, AttendanceAnalyzeResponse
from app.schemas.student import StudentAttendanceHistoryResponse, StudentClassResponse
from app.schemas.leave import LeaveRequestResponse, LeaveRequestListResponse
from app.services.attendance_service import AttendanceService, AttendanceSubmission
from app.services.student_service import StudentService
from app.services.gamification_service import GamificationService

logger = get_logger("app.api.student")

router = APIRouter(prefix="/student", tags=["Student Features"])

_MAX_IMAGE_SIZE = 5 * 1024 * 1024
_VALID_IMAGE_TYPES = {"image/jpeg", "image/png", "image/jpg"}


def _save_uploaded_image(upload_file: UploadFile, folder: str) -> str:
    target_dir = os.path.join(settings.UPLOAD_DIR, folder)
    os.makedirs(target_dir, exist_ok=True)
    ext = os.path.splitext(upload_file.filename or "")[1] or ".jpg"
    target_path = os.path.join(target_dir, f"{uuid.uuid4()}{ext}")
    with open(target_path, "wb") as buffer:
        shutil.copyfileobj(upload_file.file, buffer)
    return target_path


def _local_path_to_url(local_path: str) -> str:
    return f"/static/{os.path.relpath(local_path, settings.UPLOAD_DIR)}"


def _validate_image(image: UploadFile) -> None:
    if image.content_type not in _VALID_IMAGE_TYPES:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="Unsupported media type. Upload must be a valid JPEG or PNG image.",
        )
    if image.size is not None and image.size > _MAX_IMAGE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="Payload too large. Uploaded image cannot exceed 5MB.",
        )


def _make_leave_response(leave, student_name: str, enrollment_number: str = None) -> LeaveRequestResponse:
    return LeaveRequestResponse(
        id=leave.id,
        student_id=leave.studentId,
        student_name=student_name or "Unknown",
        enrollment_number=enrollment_number or (leave.student.enrollmentNumber if leave.student else "N/A"),
        start_date=leave.startDate,
        end_date=leave.endDate,
        reason=leave.reason,
        document_url=leave.documentUrl,
        status=leave.status,
        approved_by=leave.approvedBy,
        approver_note=leave.approverNote,
        created_at=leave.createdAt,
        updated_at=leave.updatedAt,
    )


def _student_name(student: Student) -> str:
    if not student:
        return "Unknown"
    return f"{student.firstName or ''} {student.lastName or ''}".strip()


@router.post("/attendance/mark", response_model=AttendanceMarkResponse)
async def mark_attendance(
    session_id: str = Form(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    accuracy: float = Form(...),
    image: UploadFile | None = File(None),
    student: Student = Depends(get_current_student),
    attendance_service: AttendanceService = Depends(),
) -> AttendanceMarkResponse:
    image_path = None
    if image:
        _validate_image(image)
        image_path = _save_uploaded_image(image, "attendance")
    submission = AttendanceSubmission(
        student_id=student.id, session_id=session_id,
        latitude=latitude, longitude=longitude, accuracy=accuracy, image_path=image_path,
    )
    try:
        attendance = await attendance_service.mark_attendance(submission)
        return AttendanceMarkResponse.model_validate(attendance)
    except ValueError as err:
        if image_path and os.path.exists(image_path):
            os.remove(image_path)
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(err))


@router.post("/attendance/analyze", response_model=AttendanceAnalyzeResponse)
async def analyze_attendance(
    session_id: str = Form(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    accuracy: float = Form(...),
    image: UploadFile | None = File(None),
    student: Student = Depends(get_current_student),
    attendance_service: AttendanceService = Depends(),
) -> AttendanceAnalyzeResponse:
    """Run AI scoring and validation without saving the attendance record.

    Returns scores and a short-lived review_token (5 min) that the student
    can use to confirm submission via POST /attendance/confirm.
    """
    image_path = None
    if image:
        _validate_image(image)
        image_path = _save_uploaded_image(image, "attendance")
    submission = AttendanceSubmission(
        student_id=student.id, session_id=session_id,
        latitude=latitude, longitude=longitude, accuracy=accuracy, image_path=image_path,
    )
    try:
        result = await attendance_service.analyze_attendance(submission)
        return AttendanceAnalyzeResponse(**result)
    except ValueError as err:
        if image_path and os.path.exists(image_path):
            os.remove(image_path)
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(err))


@router.post("/attendance/confirm", response_model=AttendanceMarkResponse)
async def confirm_attendance(
    review_token: str = Form(...),
    student: Student = Depends(get_current_student),
    attendance_service: AttendanceService = Depends(),
) -> AttendanceMarkResponse:
    """Confirm a previously analyzed attendance submission.

    Accepts the review_token returned by POST /attendance/analyze and saves
    the attendance record without re-running AI inference.
    """
    try:
        attendance = await attendance_service.confirm_attendance(student.id, review_token)
        return AttendanceMarkResponse.model_validate(attendance)
    except ValueError as err:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(err))


@router.post("/register-face", status_code=status.HTTP_200_OK)
async def register_face(
    image: UploadFile = File(...),
    student: Student = Depends(get_current_student),
    attendance_service: AttendanceService = Depends(),
) -> dict:
    _validate_image(image)
    image_path = _save_uploaded_image(image, "registration")
    try:
        success = await attendance_service.register_face(student.id, image_path)
        if not success:
            raise ValueError("Could not extract a valid face from the image.")
        return {"status": "success", "message": "Face embedding registered successfully."}
    except ValueError as err:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(err))
    finally:
        if os.path.exists(image_path):
            os.remove(image_path)


@router.get("/my-attendance", response_model=StudentAttendanceHistoryResponse)
async def get_my_attendance(
    student: Student = Depends(get_current_student),
    student_service: StudentService = Depends(),
) -> StudentAttendanceHistoryResponse:
    return await student_service.get_student_attendance_history(student.userId)


@router.get("/classes", response_model=list[StudentClassResponse])
async def get_my_classes(
    student: Student = Depends(get_current_student),
    student_service: StudentService = Depends(),
) -> list[StudentClassResponse]:
    return await student_service.get_student_classes(student.userId)


@router.post("/fcm-token", status_code=status.HTTP_200_OK)
async def register_fcm_token(
    payload: dict,
    student: Student = Depends(get_current_student),
) -> dict:
    token = payload.get("token")
    if not token:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="FCM token is required.")
    await db.student.update(where={"id": student.id}, data={"fcmToken": token})
    return {"status": "success", "message": "FCM token registered."}


@router.post("/attendance/{attendance_id}/note", status_code=status.HTTP_200_OK)
async def submit_flagged_note(
    attendance_id: str,
    payload: dict,
    student: Student = Depends(get_current_student),
) -> dict:
    note = payload.get("note", "").strip()
    if not note:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Note cannot be empty.")
    if len(note) > 500:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Note cannot exceed 500 characters.")
    record = await db.attendance.find_unique(where={"id": attendance_id})
    if not record or record.studentId != student.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Attendance record not found.")
    if record.status != "Flagged":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Notes can only be added to flagged records.")
    await db.attendance.update(where={"id": attendance_id}, data={"studentNote": note})
    return {"status": "success", "message": "Note submitted successfully."}


@router.get("/leaves", response_model=LeaveRequestListResponse)
async def get_my_leaves(
    student: Student = Depends(get_current_student),
    leave_repo: LeaveRepository = Depends(),
) -> LeaveRequestListResponse:
    leaves = await leave_repo.get_by_student_id(student.id)
    leave_responses = [_make_leave_response(req, _student_name(req.student)) for req in leaves]
    return LeaveRequestListResponse(
        leaves=leave_responses,
        total=len(leave_responses),
        pending=sum(1 for req in leaves if req.status == "PENDING"),
        approved=sum(1 for req in leaves if req.status == "APPROVED"),
        rejected=sum(1 for req in leaves if req.status == "REJECTED"),
    )


@router.post("/leaves", response_model=LeaveRequestResponse, status_code=status.HTTP_201_CREATED)
async def create_leave_request(
    start_date: str = Form(...),
    end_date: str = Form(...),
    reason: str = Form(...),
    document: UploadFile = File(None),
    student: Student = Depends(get_current_student),
    leave_repo: LeaveRepository = Depends(),
) -> LeaveRequestResponse:
    try:
        s_date = date.fromisoformat(start_date)
        e_date = date.fromisoformat(end_date)
    except ValueError:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid date format. Use YYYY-MM-DD.")
    if e_date < s_date:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="End date must be after or equal to start date.")
    if len(reason) < 10 or len(reason) > 500:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Reason must be between 10 and 500 characters.")

    document_url = None
    if document and document.filename:
        try:
            upload_dir = "static/leaves"
            os.makedirs(upload_dir, exist_ok=True)
            ext = os.path.splitext(document.filename)[1]
            filename = f"leave_{student.id}_{int(datetime.now().timestamp())}{ext}"
            file_path = os.path.join(upload_dir, filename)
            with open(file_path, "wb") as f:
                f.write(await document.read())
            document_url = f"/static/leaves/{filename}"
        except Exception:
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Could not save leave document.")

    leave = await leave_repo.create({
        "studentId": student.id,
        "startDate": datetime.combine(s_date, datetime.min.time()).replace(tzinfo=timezone.utc),
        "endDate": datetime.combine(e_date, datetime.max.time()).replace(tzinfo=timezone.utc),
        "reason": reason,
        "documentUrl": document_url,
        "status": "PENDING",
    })
    return _make_leave_response(leave, _student_name(student), student.enrollmentNumber)


@router.get("/smart-pass", response_model=dict)
async def get_smart_pass(student: Student = Depends(get_current_student)) -> dict:
    qr_token = create_access_token(
        subject=student.userId,
        role="STUDENT",
        expires_delta=timedelta(seconds=30),
        extra_data={"student_id": student.id, "enrollment_number": student.enrollmentNumber, "type": "smart_pass"},
    )
    return {
        "qr_token": qr_token,
        "expires_at": (datetime.now(timezone.utc) + timedelta(seconds=30)).isoformat(),
        "student_name": _student_name(student),
        "enrollment_number": student.enrollmentNumber,
    }


@router.get("/stats", response_model=dict)
async def get_my_stats(student: Student = Depends(get_current_student)) -> dict:
    return await GamificationService().get_student_stats(student.id)

