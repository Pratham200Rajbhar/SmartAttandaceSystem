from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from app.api.dependencies import get_current_teacher
from app.repositories.attendance_repo import AttendanceRepository
from app.schemas.teacher import (
    SessionResponse,
    SessionStart,
    GeofenceUpsert,
    GeofenceResponse,
    AcademicClassWithGeofenceResponse,
    SessionAttendanceResponse,
    ClassStatsResponse,
    AttendanceManualOverride,
    SessionWithClassResponse,
    BulkMarkRequest,
    AbsentStudentItem,
)
from app.schemas.attendance import AttendanceReview, FlaggedAttendanceResponse
from app.services.session_service import SessionService
from app.services.attendance_service import AttendanceService
from app.services.teacher_service import TeacherService
from app.services.leave_service import LeaveService
from app.repositories.leave_repo import LeaveRepository
from app.schemas.leave import LeaveRequestResponse, LeaveRequestApprove
from prisma.models import Teacher

router = APIRouter(prefix="/teacher", tags=["Teacher Features"])


@router.post("/sessions/start", response_model=SessionResponse)
async def start_session(
    data: SessionStart,
    teacher: Teacher = Depends(get_current_teacher),
    session_service: SessionService = Depends(),
) -> SessionResponse:
    """Open a new attendance session for one of the teacher's classes."""
    session = await session_service.start_session(data, teacher.id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not open session. Class not found or unauthorized.",
        )
    return session


@router.post("/sessions/{id}/stop", status_code=status.HTTP_200_OK)
async def stop_session(
    id: str,
    teacher: Teacher = Depends(get_current_teacher),
    session_service: SessionService = Depends(),
) -> dict:
    """Close an active attendance session."""
    success = await session_service.stop_session(id, teacher.id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Session not found, already stopped, or unauthorized.",
        )
    return {"status": "success", "message": "Session closed successfully."}


@router.get("/attendance/flagged", response_model=List[FlaggedAttendanceResponse])
async def get_flagged_attendance(
    teacher: Teacher = Depends(get_current_teacher),
    attendance_repo: AttendanceRepository = Depends(),
) -> List[FlaggedAttendanceResponse]:
    """Return all flagged attendance records across the teacher's classes."""
    records = await attendance_repo.get_flagged()
    flagged_list: List[FlaggedAttendanceResponse] = []

    for r in records:
        student_name = "Unknown Student"
        if r.student:
            first = r.student.firstName or ""
            last = r.student.lastName or ""
            full_name = f"{first} {last}".strip()
            if full_name:
                student_name = full_name
        academic_class = r.session.academicClass if r.session else None

        # Resolve subject from FK relation after migration
        subject_name = "N/A"
        if academic_class and academic_class.subject:
            subject_name = academic_class.subject.name
        elif academic_class:
            subject_name = academic_class.name  # Fallback to class name

        flagged_list.append(
            FlaggedAttendanceResponse(
                id=r.id,
                enrollment_number=r.student.enrollmentNumber if r.student else "N/A",
                student_name=student_name,
                class_name=academic_class.name if academic_class else "N/A",
                subject=subject_name,
                face_score=r.faceScore,
                liveness_score=r.livenessScore,
                background_score=r.backgroundScore,
                final_ai_score=r.finalAiScore,
                gps_latitude=r.gpsLatitude,
                gps_longitude=r.gpsLongitude,
                created_at=r.createdAt,
            )
        )
    return flagged_list


@router.put("/attendance/{id}/review", status_code=status.HTTP_200_OK)
async def review_flagged_attendance(
    id: str,
    review: AttendanceReview,
    teacher: Teacher = Depends(get_current_teacher),
    attendance_service: AttendanceService = Depends(),
) -> dict:
    """Approve or reject a flagged attendance record."""
    success = await attendance_service.review_attendance(
        attendance_id=id,
        status=review.status,
        remarks=review.remarks,
    )

    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Attendance record not found, is not currently flagged, or review failed.",
        )

    return {"status": "success", "message": f"Attendance record has been {review.status}."}


@router.get("/my-classes", response_model=List[AcademicClassWithGeofenceResponse])
async def get_my_classes(
    teacher: Teacher = Depends(get_current_teacher),
    teacher_service: TeacherService = Depends(),
) -> List[AcademicClassWithGeofenceResponse]:
    """Return all classes assigned to the authenticated teacher."""
    return await teacher_service.get_classes_by_teacher_user_id(teacher.userId)


@router.post("/classes/{class_id}/geofence", response_model=GeofenceResponse)
async def upsert_geofence(
    class_id: str,
    data: GeofenceUpsert,
    teacher: Teacher = Depends(get_current_teacher),
    teacher_service: TeacherService = Depends(),
) -> GeofenceResponse:
    """Create or update the geofence for a class the teacher owns."""
    return await teacher_service.upsert_geofence(
        user_id=teacher.userId,
        class_id=class_id,
        data=data,
    )


@router.get("/sessions/{session_id}/attendance", response_model=SessionAttendanceResponse)
async def get_session_attendance(
    session_id: str,
    teacher: Teacher = Depends(get_current_teacher),
    teacher_service: TeacherService = Depends(),
) -> SessionAttendanceResponse:
    """Return the full attendance roster for a session."""
    return await teacher_service.get_session_attendance_roster(
        user_id=teacher.userId,
        session_id=session_id,
    )


@router.get("/classes/{class_id}/stats", response_model=ClassStatsResponse)
async def get_class_stats(
    class_id: str,
    teacher: Teacher = Depends(get_current_teacher),
    teacher_service: TeacherService = Depends(),
) -> ClassStatsResponse:
    """Return aggregated attendance statistics for a class."""
    return await teacher_service.get_class_stats(
        user_id=teacher.userId,
        class_id=class_id,
    )


@router.post("/sessions/{session_id}/override", status_code=status.HTTP_200_OK)
async def manual_override_attendance(
    session_id: str,
    data: AttendanceManualOverride,
    teacher: Teacher = Depends(get_current_teacher),
    teacher_service: TeacherService = Depends(),
) -> dict:
    """Manually override a single student's attendance status for a session."""
    success = await teacher_service.manual_override_attendance(
        user_id=teacher.userId,
        session_id=session_id,
        student_id=data.student_id,
        status_val=data.status,
    )
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to apply attendance manual override.",
        )
    return {"status": "success", "message": f"Attendance overridden to {data.status}."}


@router.get("/sessions/all", response_model=List[SessionWithClassResponse])
async def get_teacher_sessions(
    teacher: Teacher = Depends(get_current_teacher),
    teacher_service: TeacherService = Depends(),
) -> List[SessionWithClassResponse]:
    """Return all sessions (active and past) for the teacher's classes."""
    return await teacher_service.get_teacher_sessions(user_id=teacher.userId)


@router.get(
    "/sessions/{session_id}/absent-students",
    response_model=List[AbsentStudentItem],
)
async def get_absent_students(
    session_id: str,
    teacher: Teacher = Depends(get_current_teacher),
    teacher_service: TeacherService = Depends(),
) -> List[AbsentStudentItem]:
    """Return all enrolled students who have not yet been marked for a session.

    Used by the Manual Entry page to show only students still needing action.
    """
    return await teacher_service.get_absent_students(
        session_id=session_id,
        user_id=teacher.userId,
    )


@router.post("/sessions/{session_id}/mark-bulk", status_code=status.HTTP_200_OK)
async def bulk_mark_attendance(
    session_id: str,
    data: BulkMarkRequest,
    teacher: Teacher = Depends(get_current_teacher),
    teacher_service: TeacherService = Depends(),
) -> dict:
    """Mark or update attendance for multiple students at once.

    Safe to call for students who already have records — uses upsert internally.
    """
    count = await teacher_service.bulk_mark_attendance(
        session_id=session_id,
        user_id=teacher.userId,
        request=data,
    )
    return {"status": "success", "count": count}


@router.get("/classes/{class_id}/export-attendance", response_model=List[dict])
async def export_class_attendance(
    class_id: str,
    from_date: Optional[datetime] = None,
    to_date: Optional[datetime] = None,
    teacher: Teacher = Depends(get_current_teacher),
    teacher_service: TeacherService = Depends(),
) -> List[dict]:
    """Return flat attendance data for CSV export.

    Optionally filtered by from_date and to_date query parameters.
    The frontend converts this JSON array to CSV via Papa.unparse.
    """
    return await teacher_service.export_class_attendance(
        class_id=class_id,
        user_id=teacher.userId,
        from_date=from_date,
        to_date=to_date,
    )


@router.get("/disputes", response_model=List[dict])
async def get_pending_disputes(
    teacher: Teacher = Depends(get_current_teacher),
    attendance_repo: AttendanceRepository = Depends(),
) -> List[dict]:
    """Get all pending disputes for students in teacher's classes."""
    # Get all attendance records with pending disputes
    from app.db.client import db
    disputes = await db.attendance.find_many(
        where={"disputeStatus": "PENDING"},
        include={
            "student": True,
            "session": {"include": {"academicClass": {"include": {"subject": True}}}}
        },
        order={"disputedAt": "asc"}
    )
    
    result = []
    for d in disputes:
        # Check if this dispute is for a class taught by this teacher
        if d.session and d.session.academicClass and d.session.academicClass.teacherId == teacher.id:
            student_name = f"{d.student.firstName or ''} {d.student.lastName or ''}".strip()
            result.append({
                "id": d.id,
                "attendance_id": d.id,
                "student_id": d.studentId,
                "student_name": student_name or "Unknown",
                "enrollment_number": d.student.enrollmentNumber,
                "class_name": d.session.academicClass.name,
                "subject": d.session.academicClass.subject.name if d.session.academicClass.subject else "N/A",
                "session_date": d.session.startTime,
                "original_status": d.status,
                "dispute_reason": d.disputeReason,
                "proof_image_url": d.proofImageUrl,
                "disputed_at": d.disputedAt
            })
    
    return result


@router.put("/disputes/{attendance_id}/resolve", status_code=status.HTTP_200_OK)
async def resolve_dispute(
    attendance_id: str,
    status: str = "RESOLVED",
    remarks: str = "",
    new_attendance_status: Optional[str] = None,
    teacher: Teacher = Depends(get_current_teacher),
    attendance_repo: AttendanceRepository = Depends(),
) -> dict:
    """Resolve a dispute by approving or rejecting it."""
    from app.db.client import db
    from datetime import datetime, timezone
    
    # Get attendance record
    record = await attendance_repo.get_by_id(attendance_id)
    if not record or record.disputeStatus != "PENDING":
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Dispute not found or already resolved."
        )
    
    # Update dispute status
    update_data = {
        "disputeStatus": status,
        "remarks": remarks,
        "resolvedAt": datetime.now(timezone.utc)
    }
    
    # If approved, update attendance status
    if status == "RESOLVED" and new_attendance_status:
        update_data["status"] = new_attendance_status
    
    await db.attendance.update(
        where={"id": attendance_id},
        data=update_data
    )
    
    return {
        "status": "success",
        "message": f"Dispute {status.lower()} successfully."
    }


@router.get("/leaves/pending", response_model=List[LeaveRequestResponse])
async def get_pending_leaves(
    teacher: Teacher = Depends(get_current_teacher),
    leave_repo: LeaveRepository = Depends(),
) -> List[LeaveRequestResponse]:
    """Get all pending leave requests for students in teacher's classes."""
    leaves = await leave_repo.get_pending_for_teacher(teacher.id)
    
    result = []
    for leave in leaves:
        student_name = f"{leave.student.firstName or ''} {leave.student.lastName or ''}".strip()
        result.append(LeaveRequestResponse(
            id=leave.id,
            student_id=leave.studentId,
            student_name=student_name or "Unknown",
            enrollment_number=leave.student.enrollmentNumber,
            start_date=leave.startDate,
            end_date=leave.endDate,
            reason=leave.reason,
            document_url=leave.documentUrl,
            status=leave.status,
            approved_by=leave.approvedBy,
            approver_note=leave.approverNote,
            created_at=leave.createdAt,
            updated_at=leave.updatedAt
        ))
    
    return result


@router.put("/leaves/{leave_id}/approve", status_code=status.HTTP_200_OK)
async def approve_leave(
    leave_id: str,
    data: LeaveRequestApprove,
    teacher: Teacher = Depends(get_current_teacher),
    leave_service: LeaveService = Depends(),
) -> dict:
    """Approve or reject a leave request."""
    result = await leave_service.approve_leave(
        leave_id=leave_id,
        teacher_id=teacher.id,
        status=data.status,
        approver_note=data.approver_note
    )
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Leave request not found."
        )
    
    return {
        "status": "success",
        "message": f"Leave request {data.status.lower()} successfully."
    }
