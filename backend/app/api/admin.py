from functools import wraps

from fastapi import APIRouter, Depends, HTTPException, Request, status
from prisma.models import User

from app.api.dependencies import RoleChecker, get_current_user
from app.db.client import db
from app.repositories.attendance_repo import AttendanceRepository
from app.schemas.student import StudentCreate, StudentResponse, StudentUpdate
from app.schemas.teacher import TeacherCreate, TeacherResponse, TeacherUpdate
from app.schemas.admin import (
    ClassCreate, ClassUpdate, ClassResponse, AssignTeacherRequest, EnrollRequest,
    DepartmentCreate, DepartmentUpdate, DepartmentResponse,
    AuditLogResponse, AdminStatsResponse, AdminResetPasswordRequest,
)
from app.schemas.master_data import (
    SubjectCreate, SubjectUpdate, SubjectResponse,
    ClassroomCreate, ClassroomUpdate, ClassroomResponse,
    DesignationCreate, DesignationUpdate, DesignationResponse,
)
from app.services.admin_service import AdminService
from app.services.absentee_scanner import run_absentee_scan

admin_protection = Depends(RoleChecker(allowed_roles=["ADMIN"]))
router = APIRouter(prefix="/admin", tags=["Admin System Operations"], dependencies=[admin_protection])


def _get_client_ip(request: Request) -> str:
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else "unknown"


def _handle_value_err(func):
    @wraps(func)
    async def wrapper(*args, **kwargs):
        try:
            return await func(*args, **kwargs)
        except ValueError as err:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(err))
        except Exception as err:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(err))
    return wrapper


def _handle_generic_err(func):
    @wraps(func)
    async def wrapper(*args, **kwargs):
        try:
            return await func(*args, **kwargs)
        except Exception as err:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(err))
    return wrapper


@router.post("/users/student", response_model=StudentResponse, status_code=status.HTTP_201_CREATED)
@_handle_generic_err
async def create_student(data: StudentCreate, request: Request, current_user: User = Depends(get_current_user), admin_service: AdminService = Depends()):
    return await admin_service.create_student(data, actor=current_user.email, ip=_get_client_ip(request))


@router.post("/users/teacher", response_model=TeacherResponse, status_code=status.HTTP_201_CREATED)
@_handle_generic_err
async def create_teacher(data: TeacherCreate, request: Request, current_user: User = Depends(get_current_user), admin_service: AdminService = Depends()):
    return await admin_service.create_teacher(data, actor=current_user.email, ip=_get_client_ip(request))


@router.post("/classes", response_model=ClassResponse, status_code=status.HTTP_201_CREATED)
@_handle_value_err
async def create_class(data: ClassCreate, request: Request, current_user: User = Depends(get_current_user), admin_service: AdminService = Depends()):
    return await admin_service.create_class(data, actor=current_user.email, ip=_get_client_ip(request))


@router.put("/classes/{class_id}/assign-teacher", response_model=ClassResponse)
@_handle_value_err
async def assign_teacher(class_id: str, data: AssignTeacherRequest, request: Request, current_user: User = Depends(get_current_user), admin_service: AdminService = Depends()):
    return await admin_service.assign_teacher(class_id=class_id, teacher_id=data.teacher_id, actor=current_user.email, ip=_get_client_ip(request))


@router.post("/classes/{class_id}/enroll", status_code=status.HTTP_200_OK)
@_handle_value_err
async def enroll_students(class_id: str, data: EnrollRequest, request: Request, current_user: User = Depends(get_current_user), admin_service: AdminService = Depends()) -> dict:
    enrolled_count = await admin_service.enroll_students(class_id=class_id, student_ids=data.student_ids, actor=current_user.email, ip=_get_client_ip(request))
    return {"status": "success", "enrolled_count": enrolled_count}


@router.get("/users/students", response_model=list[StudentResponse])
async def get_students(admin_service: AdminService = Depends()):
    return await admin_service.get_all_students()


@router.get("/users/students/{id}", response_model=StudentResponse)
async def get_student_by_id(id: str, admin_service: AdminService = Depends()):
    student = await db.student.find_unique(where={"id": id}, include={"user": True, "department": True})
    if not student:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found")
    return StudentResponse(
        id=student.id, user_id=student.userId, enrollment_number=student.enrollmentNumber,
        email=student.user.email if student.user else "", first_name=student.firstName,
        last_name=student.lastName, phone=student.phone, gender=student.gender,
        date_of_birth=student.dateOfBirth, department_id=student.departmentId,
        department_name=student.department.name if student.department else None,
        semester=student.semester, batch=student.batch,
    )


@router.put("/users/students/{id}", response_model=StudentResponse)
@_handle_generic_err
async def update_student(id: str, data: StudentUpdate, request: Request, current_user: User = Depends(get_current_user), admin_service: AdminService = Depends()):
    return await admin_service.update_student(id, data.model_dump(exclude_unset=True), actor=current_user.email, ip=_get_client_ip(request))



@router.get("/users/teachers", response_model=list[TeacherResponse])
async def get_teachers(admin_service: AdminService = Depends()):
    return await admin_service.get_all_teachers()


@router.get("/users/teachers/{id}", response_model=TeacherResponse)
async def get_teacher_by_id(id: str):
    teacher = await db.teacher.find_unique(where={"id": id}, include={"user": True, "department": True, "designation": True})
    if not teacher:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Teacher not found")
    return TeacherResponse(
        id=teacher.id, user_id=teacher.userId, email=teacher.user.email if teacher.user else "",
        employee_id=teacher.employeeId, first_name=teacher.firstName, last_name=teacher.lastName,
        department_id=teacher.departmentId, designation_id=teacher.designationId,
        department=teacher.department.name if teacher.department else "",
        designation=teacher.designation.name if teacher.designation else "",
        phone=teacher.phone, qualification=teacher.qualification, specialization=teacher.specialization,
        experience_years=teacher.experienceYears, joining_date=teacher.joiningDate,
    )


@router.put("/users/teachers/{id}", response_model=TeacherResponse)
@_handle_generic_err
async def update_teacher(id: str, data: TeacherUpdate, request: Request, current_user: User = Depends(get_current_user), admin_service: AdminService = Depends()):
    return await admin_service.update_teacher(id, data.model_dump(exclude_unset=True), actor=current_user.email, ip=_get_client_ip(request))


@router.put("/users/{user_id}/reset-password")
async def reset_user_password(user_id: str, data: AdminResetPasswordRequest, request: Request, current_user: User = Depends(get_current_user), admin_service: AdminService = Depends()):
    try:
        await admin_service.reset_user_password(user_id, data.new_password, actor=current_user.email, ip=_get_client_ip(request))
        return {"status": "success", "message": "Password updated successfully"}
    except ValueError as err:
        raise HTTPException(status_code=404, detail=str(err))
    except Exception as err:
        raise HTTPException(status_code=400, detail=str(err))


@router.get("/classes", response_model=list[ClassResponse])
async def get_classes(admin_service: AdminService = Depends()):
    return await admin_service.get_all_classes()


@router.get("/classes/{class_id}", response_model=ClassResponse)
async def get_class_by_id(class_id: str, admin_service: AdminService = Depends()):
    cls = await db.academicclass.find_unique(where={"id": class_id}, include={"subject": True, "classroom": True, "enrollments": True})
    if not cls:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Class not found")
    return ClassResponse(
        id=cls.id, name=cls.name, subject_name=cls.subject.name if cls.subject else "",
        subject_code=cls.subject.code if cls.subject else "", teacherId=cls.teacherId,
        classroom_name=cls.classroom.name if cls.classroom else None,
        semester=cls.semester, batch=cls.batch, max_students=cls.maxStudents,
        enrolled_count=len(cls.enrollments) if cls.enrollments else 0,
        enrolled_student_ids=[e.studentId for e in cls.enrollments] if cls.enrollments else [],
    )


@router.put("/classes/{class_id}", response_model=ClassResponse)
@_handle_generic_err
async def update_class(class_id: str, data: ClassUpdate, request: Request, current_user: User = Depends(get_current_user), admin_service: AdminService = Depends()):
    return await admin_service.update_class(class_id, data.model_dump(exclude_unset=True), actor=current_user.email, ip=_get_client_ip(request))


# --- Departments ---
@router.get("/departments", response_model=list[DepartmentResponse])
async def get_departments(admin_service: AdminService = Depends()):
    return await admin_service.get_all_departments()


@router.get("/departments/{id}", response_model=DepartmentResponse)
async def get_department(id: str, admin_service: AdminService = Depends()):
    dept = await admin_service.get_department_by_id(id)
    if not dept:
        raise HTTPException(status_code=404, detail="Department not found")
    return dept


@router.post("/departments", response_model=DepartmentResponse)
@_handle_generic_err
async def create_department(data: DepartmentCreate, admin_service: AdminService = Depends()):
    return await admin_service.create_department(data.name, data.code, data.head, data.description)


@router.put("/departments/{id}", response_model=DepartmentResponse)
@_handle_generic_err
async def update_department(id: str, data: DepartmentUpdate, admin_service: AdminService = Depends()):
    return await admin_service.update_department(id, data.model_dump(exclude_unset=True))


@router.delete("/departments/{id}")
async def delete_department(id: str, request: Request, current_user: User = Depends(get_current_user), admin_service: AdminService = Depends()):
    try:
        await admin_service.delete_department(id, actor=current_user.email, ip=_get_client_ip(request))
        return {"status": "success"}
    except ValueError as err:
        raise HTTPException(status_code=400, detail=str(err))
    except Exception:
        raise HTTPException(status_code=500, detail="Internal server error")


# --- Subjects ---
@router.get("/subjects", response_model=list[SubjectResponse])
async def get_subjects(admin_service: AdminService = Depends()):
    return await admin_service.get_all_subjects()


@router.get("/subjects/{id}", response_model=SubjectResponse)
async def get_subject(id: str, admin_service: AdminService = Depends()):
    sub = await admin_service.get_subject_by_id(id)
    if not sub:
        raise HTTPException(status_code=404, detail="Subject not found")
    return sub


@router.post("/subjects", response_model=SubjectResponse)
@_handle_generic_err
async def create_subject(data: SubjectCreate, admin_service: AdminService = Depends()):
    return await admin_service.create_subject(data.name, data.code, data.description)


@router.put("/subjects/{id}", response_model=SubjectResponse)
@_handle_generic_err
async def update_subject(id: str, data: SubjectUpdate, admin_service: AdminService = Depends()):
    return await admin_service.update_subject(id, data.model_dump(exclude_unset=True))


@router.delete("/subjects/{id}")
async def delete_subject(id: str, request: Request, current_user: User = Depends(get_current_user), admin_service: AdminService = Depends()):
    try:
        await admin_service.delete_subject(id, actor=current_user.email, ip=_get_client_ip(request))
        return {"status": "success"}
    except ValueError as err:
        raise HTTPException(status_code=400, detail=str(err))
    except Exception:
        raise HTTPException(status_code=500, detail="Internal server error")


# --- Classrooms ---
@router.get("/classrooms", response_model=list[ClassroomResponse])
async def get_classrooms(admin_service: AdminService = Depends()):
    return await admin_service.get_all_classrooms()


@router.get("/classrooms/{id}", response_model=ClassroomResponse)
async def get_classroom(id: str, admin_service: AdminService = Depends()):
    classroom = await admin_service.get_classroom_by_id(id)
    if not classroom:
        raise HTTPException(status_code=404, detail="Classroom not found")
    return classroom


@router.post("/classrooms", response_model=ClassroomResponse)
@_handle_generic_err
async def create_classroom(data: ClassroomCreate, admin_service: AdminService = Depends()):
    return await admin_service.create_classroom(data.name, data.building, data.capacity)


@router.put("/classrooms/{id}", response_model=ClassroomResponse)
@_handle_generic_err
async def update_classroom(id: str, data: ClassroomUpdate, admin_service: AdminService = Depends()):
    return await admin_service.update_classroom(id, data.model_dump(exclude_unset=True))


@router.delete("/classrooms/{id}")
async def delete_classroom(id: str, request: Request, current_user: User = Depends(get_current_user), admin_service: AdminService = Depends()):
    try:
        await admin_service.delete_classroom(id, actor=current_user.email, ip=_get_client_ip(request))
        return {"status": "success"}
    except ValueError as err:
        raise HTTPException(status_code=400, detail=str(err))
    except Exception:
        raise HTTPException(status_code=500, detail="Internal server error")


# --- Designations ---
@router.get("/designations", response_model=list[DesignationResponse])
async def get_designations(admin_service: AdminService = Depends()):
    return await admin_service.get_all_designations()


@router.get("/designations/{id}", response_model=DesignationResponse)
async def get_designation(id: str, admin_service: AdminService = Depends()):
    desig = await admin_service.get_designation_by_id(id)
    if not desig:
        raise HTTPException(status_code=404, detail="Designation not found")
    return desig


@router.post("/designations", response_model=DesignationResponse)
@_handle_generic_err
async def create_designation(data: DesignationCreate, admin_service: AdminService = Depends()):
    return await admin_service.create_designation(data.name, data.code, data.description)


@router.put("/designations/{id}", response_model=DesignationResponse)
@_handle_generic_err
async def update_designation(id: str, data: DesignationUpdate, admin_service: AdminService = Depends()):
    return await admin_service.update_designation(id, data.model_dump(exclude_unset=True))


@router.delete("/designations/{id}")
async def delete_designation(id: str, request: Request, current_user: User = Depends(get_current_user), admin_service: AdminService = Depends()):
    try:
        await admin_service.delete_designation(id, actor=current_user.email, ip=_get_client_ip(request))
        return {"status": "success"}
    except ValueError as err:
        raise HTTPException(status_code=400, detail=str(err))
    except Exception:
        raise HTTPException(status_code=500, detail="Internal server error")


# --- Misc Admin ---
@router.get("/audit", response_model=list[AuditLogResponse])
async def get_audit_logs(admin_service: AdminService = Depends()):
    return await admin_service.get_audit_logs()


@router.get("/stats", response_model=AdminStatsResponse)
async def get_admin_stats(admin_service: AdminService = Depends()):
    return await admin_service.get_stats()


@router.post("/scan-absentees", status_code=status.HTTP_200_OK)
async def scan_absentee_anomalies(
    contamination: float = 0.10,
    attendance_repo: AttendanceRepository = Depends(),
) -> list[dict]:
    records = await attendance_repo.get_all_absences()
    if not records or len(records) < 5:
        return []
    
    student_map = {}
    for r in records:
        if r.student:
            first_name = r.student.firstName or ""
            last_name = r.student.lastName or ""
            full_name = f"{first_name} {last_name}".strip() or "Unknown Student"
            student_map[r.studentId] = {
                "student_name": full_name,
                "enrollment_number": r.student.enrollmentNumber,
            }

    rows = [{"student_id": r.studentId, "status": r.status, "day_of_week": r.createdAt.strftime("%A")} for r in records]
    try:
        flagged = await run_absentee_scan(attendance_records=rows, contamination=contamination)
        for item in flagged:
            s_id = item.get("student_id")
            s_info = student_map.get(s_id, {})
            item["student_name"] = s_info.get("student_name", "Unknown Student")
            item["enrollment_number"] = s_info.get("enrollment_number", "N/A")
        return flagged
    except Exception as err:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Outlier pattern extraction failed: {str(err)}")


# --- System Config ---
from app.schemas.system_config import SystemConfigResponse, SystemConfigUpdate
from app.services.system_config_service import SystemConfigService

@router.get("/config", response_model=SystemConfigResponse)
async def get_system_config(config_service: SystemConfigService = Depends()):
    return await config_service.get_config()


@router.patch("/config", response_model=SystemConfigResponse)
async def update_system_config(data: SystemConfigUpdate, config_service: SystemConfigService = Depends()):
    return await config_service.update_config(
        is_face_recognition_enabled=data.is_face_recognition_enabled,
        is_gps_verification_enabled=data.is_gps_verification_enabled,
        is_ai_background_validation_enabled=data.is_ai_background_validation_enabled,
    )


