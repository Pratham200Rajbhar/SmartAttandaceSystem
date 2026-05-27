from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from prisma.models import Teacher

from app.api.dependencies import get_current_teacher
from app.db.client import db
from app.repositories.attendance_repo import AttendanceRepository
from app.repositories.leave_repo import LeaveRepository
from app.schemas.teacher import (
    SessionResponse, SessionStart, GeofenceUpsert, GeofenceResponse,
    AcademicClassWithGeofenceResponse, SessionAttendanceResponse,
    ClassStatsResponse, AttendanceManualOverride, SessionWithClassResponse,
    BulkMarkRequest, AbsentStudentItem, DeviceChangeResponse, DeviceChangeApprove
)
from app.schemas.attendance import AttendanceReview, FlaggedAttendanceResponse
from app.schemas.leave import LeaveRequestResponse, LeaveRequestApprove
from app.services.session_service import SessionService
from app.services.attendance_service import AttendanceService
from app.services.teacher_service import TeacherService
from app.services.leave_service import LeaveService
from app.services.device_change_service import DeviceChangeService

router = APIRouter(prefix="/teacher", tags=["Teacher Features"])


def _make_leave_response(leave) -> LeaveRequestResponse:
    name = f"{leave.student.firstName or ''} {leave.student.lastName or ''}".strip()
    return LeaveRequestResponse(
        id=leave.id, student_id=leave.studentId, student_name=name or "Unknown",
        enrollment_number=leave.student.enrollmentNumber,
        start_date=leave.startDate, end_date=leave.endDate, reason=leave.reason,
        document_url=leave.documentUrl, status=leave.status, approved_by=leave.approvedBy,
        approver_note=leave.approverNote, created_at=leave.createdAt, updated_at=leave.updatedAt,
    )


@router.post("/sessions/start", response_model=SessionResponse)
async def start_session(
    data: SessionStart,
    teacher: Teacher = Depends(get_current_teacher),
    session_service: SessionService = Depends(),
) -> SessionResponse:
    session = await session_service.start_session(data, teacher.id)
    if not session:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Could not open session. Class not found or unauthorized.")
    return session


@router.post("/sessions/{id}/stop", status_code=status.HTTP_200_OK)
async def stop_session(
    id: str,
    teacher: Teacher = Depends(get_current_teacher),
    session_service: SessionService = Depends(),
) -> dict:
    if not await session_service.stop_session(id, teacher.id):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Session not found, already stopped, or unauthorized.")
    return {"status": "success", "message": "Session closed successfully."}


@router.get("/attendance/flagged", response_model=list[FlaggedAttendanceResponse])
async def get_flagged_attendance(
    teacher: Teacher = Depends(get_current_teacher),
    attendance_repo: AttendanceRepository = Depends(),
) -> list[FlaggedAttendanceResponse]:
    classes = await db.academicclass.find_many(where={"teacherId": teacher.id})
    my_class_ids = [c.id for c in classes]
    records = await db.attendance.find_many(
        where={"status": "Flagged", "session": {"is": {"academicClassId": {"in": my_class_ids}}}},
        include={
            "student": {"include": {"user": True}},
            "session": {"include": {"academicClass": {"include": {"subject": True}}}},
        },
    )
    return [
        FlaggedAttendanceResponse(
            id=r.id,
            enrollment_number=r.student.enrollmentNumber if r.student else "N/A",
            student_name=(
                f"{r.student.firstName or ''} {r.student.lastName or ''}".strip()
                if r.student else "Unknown Student"
            ),
            class_name=ac.subject.name if (ac := r.session.academicClass if r.session else None) and ac.subject else (ac.name if ac else "N/A"),
            subject=ac.subject.name if ac and ac.subject else (ac.name if ac else "N/A"),
            face_score=r.faceScore, liveness_score=r.livenessScore,
            background_score=r.backgroundScore, final_ai_score=r.finalAiScore,
            gps_latitude=r.gpsLatitude, gps_longitude=r.gpsLongitude,
            created_at=r.createdAt,
            student_note=r.studentNote,
        )
        for r in records
    ]


@router.get("/attendance/{id}", response_model=FlaggedAttendanceResponse)
async def get_attendance_by_id(id: str, attendance_repo: AttendanceRepository = Depends()):
    r = await attendance_repo.get_by_id(id)
    if not r:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Attendance record not found")
    ac = r.session.academicClass if r.session else None
    return FlaggedAttendanceResponse(
        id=r.id, enrollment_number=r.student.enrollmentNumber if r.student else "N/A",
        student_name=(f"{r.student.firstName or ''} {r.student.lastName or ''}".strip() if r.student else "Unknown Student"),
        class_name=ac.name if ac else "N/A", subject=ac.subject.name if ac and ac.subject else (ac.name if ac else "N/A"),
        face_score=r.faceScore, liveness_score=r.livenessScore,
        background_score=r.backgroundScore, final_ai_score=r.finalAiScore,
        gps_latitude=r.gpsLatitude, gps_longitude=r.gpsLongitude, created_at=r.createdAt,
        student_note=r.studentNote,
    )


@router.put("/attendance/{id}/review", status_code=status.HTTP_200_OK)
async def review_flagged_attendance(
    id: str,
    review: AttendanceReview,
    teacher: Teacher = Depends(get_current_teacher),
    attendance_service: AttendanceService = Depends(),
) -> dict:
    if not await attendance_service.review_attendance(attendance_id=id, status=review.status, remarks=review.remarks):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Attendance record not found, is not currently flagged, or review failed.")
    return {"status": "success", "message": f"Attendance record has been {review.status}."}


@router.get("/my-classes", response_model=list[AcademicClassWithGeofenceResponse])
async def get_my_classes(
    teacher: Teacher = Depends(get_current_teacher),
    teacher_service: TeacherService = Depends(),
) -> list[AcademicClassWithGeofenceResponse]:
    return await teacher_service.get_classes_by_teacher_user_id(teacher.userId)


@router.post("/classes/{class_id}/geofence", response_model=GeofenceResponse)
async def upsert_geofence(
    class_id: str, data: GeofenceUpsert,
    teacher: Teacher = Depends(get_current_teacher),
    teacher_service: TeacherService = Depends(),
) -> GeofenceResponse:
    return await teacher_service.upsert_geofence(user_id=teacher.userId, class_id=class_id, data=data)


@router.get("/sessions/{session_id}/attendance", response_model=SessionAttendanceResponse)
async def get_session_attendance(
    session_id: str,
    teacher: Teacher = Depends(get_current_teacher),
    teacher_service: TeacherService = Depends(),
) -> SessionAttendanceResponse:
    return await teacher_service.get_session_attendance_roster(user_id=teacher.userId, session_id=session_id)


@router.get("/classes/{class_id}/stats", response_model=ClassStatsResponse)
async def get_class_stats(
    class_id: str,
    teacher: Teacher = Depends(get_current_teacher),
    teacher_service: TeacherService = Depends(),
) -> ClassStatsResponse:
    return await teacher_service.get_class_stats(user_id=teacher.userId, class_id=class_id)


@router.post("/sessions/{session_id}/override", status_code=status.HTTP_200_OK)
async def manual_override_attendance(
    session_id: str, data: AttendanceManualOverride,
    teacher: Teacher = Depends(get_current_teacher),
    teacher_service: TeacherService = Depends(),
) -> dict:
    if not await teacher_service.manual_override_attendance(user_id=teacher.userId, session_id=session_id, student_id=data.student_id, status_val=data.status):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Failed to apply attendance manual override.")
    return {"status": "success", "message": f"Attendance overridden to {data.status}."}


@router.get("/sessions/all", response_model=list[SessionWithClassResponse])
async def get_teacher_sessions(
    teacher: Teacher = Depends(get_current_teacher),
    teacher_service: TeacherService = Depends(),
) -> list[SessionWithClassResponse]:
    return await teacher_service.get_teacher_sessions(user_id=teacher.userId)


@router.get("/sessions/{session_id}/absent-students", response_model=list[AbsentStudentItem])
async def get_absent_students(
    session_id: str,
    teacher: Teacher = Depends(get_current_teacher),
    teacher_service: TeacherService = Depends(),
) -> list[AbsentStudentItem]:
    return await teacher_service.get_absent_students(session_id=session_id, user_id=teacher.userId)


@router.post("/sessions/{session_id}/mark-bulk", status_code=status.HTTP_200_OK)
async def bulk_mark_attendance(
    session_id: str, data: BulkMarkRequest,
    teacher: Teacher = Depends(get_current_teacher),
    teacher_service: TeacherService = Depends(),
) -> dict:
    count = await teacher_service.bulk_mark_attendance(session_id=session_id, user_id=teacher.userId, request=data)
    return {"status": "success", "count": count}


@router.get("/classes/{class_id}/export-attendance", response_model=list[dict])
async def export_class_attendance(
    class_id: str,
    from_date: Optional[datetime] = None,
    to_date: Optional[datetime] = None,
    teacher: Teacher = Depends(get_current_teacher),
    teacher_service: TeacherService = Depends(),
) -> list[dict]:
    return await teacher_service.export_class_attendance(class_id=class_id, user_id=teacher.userId, from_date=from_date, to_date=to_date)


@router.get("/leaves/pending", response_model=list[LeaveRequestResponse])
async def get_pending_leaves(
    teacher: Teacher = Depends(get_current_teacher),
    leave_repo: LeaveRepository = Depends(),
) -> list[LeaveRequestResponse]:
    return [_make_leave_response(leave) for leave in await leave_repo.get_pending_for_teacher(teacher.id)]


@router.put("/leaves/{leave_id}/approve", status_code=status.HTTP_200_OK)
async def approve_leave(
    leave_id: str, data: LeaveRequestApprove,
    teacher: Teacher = Depends(get_current_teacher),
    leave_service: LeaveService = Depends(),
) -> dict:
    result = await leave_service.approve_leave(leave_id=leave_id, teacher_id=teacher.id, status=data.status, approver_note=data.approver_note)
    if not result:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Leave request not found.")
    return {"status": "success", "message": f"Leave request {data.status.lower()} successfully."}


@router.get("/device-changes/pending", response_model=list[DeviceChangeResponse])
async def get_pending_device_changes(
    teacher: Teacher = Depends(get_current_teacher),
    device_change_service: DeviceChangeService = Depends(),
) -> list[DeviceChangeResponse]:
    return await device_change_service.get_pending_requests(teacher_id=teacher.id)


@router.put("/device-changes/{request_id}/approve", status_code=status.HTTP_200_OK)
async def approve_device_change(
    request_id: str, data: DeviceChangeApprove,
    teacher: Teacher = Depends(get_current_teacher),
    device_change_service: DeviceChangeService = Depends(),
) -> dict:
    result = await device_change_service.approve_request(request_id=request_id, teacher_id=teacher.id, new_status=data.status)
    if not result:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Device change request not found or not pending.")
    return {"status": "success", "message": f"Device change request {data.status.lower()} successfully."}

