from typing import List

from fastapi import APIRouter, Depends, HTTPException, status

from app.api.dependencies import RoleChecker

from app.repositories.attendance_repo import AttendanceRepository

from app.schemas.student import StudentCreate, StudentResponse, StudentUpdate

from app.schemas.teacher import TeacherCreate, TeacherResponse, TeacherUpdate

from app.schemas.admin import (

    ClassCreate, ClassUpdate, ClassResponse, AssignTeacherRequest, EnrollRequest,

    DepartmentCreate, DepartmentUpdate, DepartmentResponse,

    AuditLogResponse, AdminStatsResponse, AdminResetPasswordRequest

)

from app.schemas.master_data import (

    SubjectCreate, SubjectUpdate, SubjectResponse,

    ClassroomCreate, ClassroomUpdate, ClassroomResponse,

    DesignationCreate, DesignationUpdate, DesignationResponse

)

from app.services.admin_service import AdminService

from app.services.absentee_scanner import run_absentee_scan

admin_protection = Depends(RoleChecker(allowed_roles=["ADMIN"]))

router = APIRouter(prefix="/admin", tags=["Admin System Operations"], dependencies=[admin_protection])

@router.post("/users/student", response_model=StudentResponse, status_code=status.HTTP_201_CREATED)

async def create_student(

    data: StudentCreate,

    admin_service: AdminService = Depends()

) -> StudentResponse:

    try:

        student = await admin_service.create_student(data)

        return student

    except Exception as err:

        raise HTTPException(

            status_code=status.HTTP_400_BAD_REQUEST,

            detail=str(err)

        )

@router.post("/users/teacher", response_model=TeacherResponse, status_code=status.HTTP_201_CREATED)

async def create_teacher(

    data: TeacherCreate,

    admin_service: AdminService = Depends()

) -> TeacherResponse:

    try:

        teacher = await admin_service.create_teacher(data)

        return teacher

    except Exception as err:

        raise HTTPException(

            status_code=status.HTTP_400_BAD_REQUEST,

            detail=str(err)

        )

@router.post("/classes", response_model=ClassResponse, status_code=status.HTTP_201_CREATED)

async def create_class(

    data: ClassCreate,

    admin_service: AdminService = Depends()

) -> ClassResponse:

    try:

        return await admin_service.create_class(data)

    except ValueError as err:

        raise HTTPException(

            status_code=status.HTTP_404_NOT_FOUND,

            detail=str(err)

        )

    except Exception as err:

        raise HTTPException(

            status_code=status.HTTP_400_BAD_REQUEST,

            detail=str(err)

        )

@router.put("/classes/{class_id}/assign-teacher", response_model=ClassResponse)

async def assign_teacher(

    class_id: str,

    data: AssignTeacherRequest,

    admin_service: AdminService = Depends()

) -> ClassResponse:

    try:

        return await admin_service.assign_teacher(

            class_id=class_id,

            teacher_id=data.teacher_id

        )

    except ValueError as err:

        raise HTTPException(

            status_code=status.HTTP_404_NOT_FOUND,

            detail=str(err)

        )

    except Exception as err:

        raise HTTPException(

            status_code=status.HTTP_400_BAD_REQUEST,

            detail=str(err)

        )

@router.post("/classes/{class_id}/enroll", status_code=status.HTTP_200_OK)

async def enroll_students(

    class_id: str,

    data: EnrollRequest,

    admin_service: AdminService = Depends()

) -> dict:

    try:

        enrolled_count = await admin_service.enroll_students(

            class_id=class_id,

            student_ids=data.student_ids

        )

        return {"status": "success", "enrolled_count": enrolled_count}

    except ValueError as err:

        raise HTTPException(

            status_code=status.HTTP_404_NOT_FOUND,

            detail=str(err)

        )

    except Exception as err:

        raise HTTPException(

            status_code=status.HTTP_400_BAD_REQUEST,

            detail=str(err)

        )

@router.get("/users/students", response_model=List[StudentResponse])

async def get_students(admin_service: AdminService = Depends()):

    return await admin_service.get_all_students()

@router.put("/users/students/{id}", response_model=StudentResponse)

async def update_student(id: str, data: StudentUpdate, admin_service: AdminService = Depends()):

    try:

        return await admin_service.update_student(id, data.model_dump(exclude_unset=True))

    except Exception as err:

        raise HTTPException(status_code=400, detail=str(err))

@router.put("/users/students/{id}/reset-device")

async def reset_student_device(id: str, admin_service: AdminService = Depends()):

    try:

        from app.db.client import db

        student = await db.student.find_unique(where={"id": id})

        if not student:

            raise ValueError("Student not found")

        await db.student.update(

            where={"id": id},

            data={

                "deviceUuid": None,

                "deviceResetRequested": False

            }

        )

        return {"status": "success", "message": "Device binding reset successfully"}

    except ValueError as err:

        raise HTTPException(status_code=404, detail=str(err))

    except Exception as err:

        raise HTTPException(status_code=400, detail=str(err))

@router.get("/users/teachers", response_model=List[TeacherResponse])

async def get_teachers(admin_service: AdminService = Depends()):

    return await admin_service.get_all_teachers()

@router.put("/users/teachers/{id}", response_model=TeacherResponse)

async def update_teacher(id: str, data: TeacherUpdate, admin_service: AdminService = Depends()):

    try:

        return await admin_service.update_teacher(id, data.model_dump(exclude_unset=True))

    except Exception as err:

        raise HTTPException(status_code=400, detail=str(err))

@router.put("/users/{user_id}/reset-password")

async def reset_user_password(

    user_id: str,

    data: AdminResetPasswordRequest,

    admin_service: AdminService = Depends()

):

    try:

        await admin_service.reset_user_password(user_id, data.new_password)

        return {"status": "success", "message": "Password updated successfully"}

    except ValueError as err:

        raise HTTPException(status_code=404, detail=str(err))

    except Exception as err:

        raise HTTPException(status_code=400, detail=str(err))

@router.get("/classes", response_model=List[ClassResponse])

async def get_classes(admin_service: AdminService = Depends()) -> List[ClassResponse]:

    return await admin_service.get_all_classes()

@router.put("/classes/{class_id}", response_model=ClassResponse)

async def update_class(

    class_id: str,

    data: ClassUpdate,

    admin_service: AdminService = Depends()

) -> ClassResponse:

    try:

        return await admin_service.update_class(class_id, data.model_dump(exclude_unset=True))

    except Exception as err:

        raise HTTPException(

            status_code=status.HTTP_400_BAD_REQUEST,

            detail=str(err)

        )

@router.get("/departments", response_model=List[DepartmentResponse])

async def get_departments(admin_service: AdminService = Depends()):

    return await admin_service.get_all_departments()

@router.get("/departments/{id}", response_model=DepartmentResponse)

async def get_department(id: str, admin_service: AdminService = Depends()):

    dept = await admin_service.get_department_by_id(id)

    if not dept:

        raise HTTPException(status_code=404, detail="Department not found")

    return dept

@router.post("/departments", response_model=DepartmentResponse)

async def create_department(data: DepartmentCreate, admin_service: AdminService = Depends()):

    try:

        return await admin_service.create_department(data.name, data.code, data.head, data.description)

    except Exception as err:

        raise HTTPException(status_code=400, detail=str(err))

@router.put("/departments/{id}", response_model=DepartmentResponse)

async def update_department(id: str, data: DepartmentUpdate, admin_service: AdminService = Depends()):

    try:

        return await admin_service.update_department(id, data.model_dump(exclude_unset=True))

    except Exception as err:

        raise HTTPException(status_code=400, detail=str(err))

@router.delete("/departments/{id}")

async def delete_department(id: str, admin_service: AdminService = Depends()):

    try:

        await admin_service.delete_department(id)

        return {"status": "success"}

    except ValueError as err:

        raise HTTPException(status_code=400, detail=str(err))

    except Exception:

        raise HTTPException(status_code=500, detail="Internal server error")

@router.get("/subjects", response_model=List[SubjectResponse])

async def get_subjects(admin_service: AdminService = Depends()):

    return await admin_service.get_all_subjects()

@router.get("/subjects/{id}", response_model=SubjectResponse)

async def get_subject(id: str, admin_service: AdminService = Depends()):

    sub = await admin_service.get_subject_by_id(id)

    if not sub:

        raise HTTPException(status_code=404, detail="Subject not found")

    return sub

@router.post("/subjects", response_model=SubjectResponse)

async def create_subject(data: SubjectCreate, admin_service: AdminService = Depends()):

    try:

        return await admin_service.create_subject(data.name, data.code, data.description)

    except Exception as err:

        raise HTTPException(status_code=400, detail=str(err))

@router.put("/subjects/{id}", response_model=SubjectResponse)

async def update_subject(id: str, data: SubjectUpdate, admin_service: AdminService = Depends()):

    try:

        return await admin_service.update_subject(id, data.model_dump(exclude_unset=True))

    except Exception as err:

        raise HTTPException(status_code=400, detail=str(err))

@router.delete("/subjects/{id}")

async def delete_subject(id: str, admin_service: AdminService = Depends()):

    try:

        await admin_service.delete_subject(id)

        return {"status": "success"}

    except ValueError as err:

        raise HTTPException(status_code=400, detail=str(err))

    except Exception:

        raise HTTPException(status_code=500, detail="Internal server error")

@router.get("/classrooms", response_model=List[ClassroomResponse])

async def get_classrooms(admin_service: AdminService = Depends()):

    return await admin_service.get_all_classrooms()

@router.get("/classrooms/{id}", response_model=ClassroomResponse)

async def get_classroom(id: str, admin_service: AdminService = Depends()):

    classroom = await admin_service.get_classroom_by_id(id)

    if not classroom:

        raise HTTPException(status_code=404, detail="Classroom not found")

    return classroom

@router.post("/classrooms", response_model=ClassroomResponse)

async def create_classroom(data: ClassroomCreate, admin_service: AdminService = Depends()):

    try:

        return await admin_service.create_classroom(data.name, data.building, data.capacity)

    except Exception as err:

        raise HTTPException(status_code=400, detail=str(err))

@router.put("/classrooms/{id}", response_model=ClassroomResponse)

async def update_classroom(id: str, data: ClassroomUpdate, admin_service: AdminService = Depends()):

    try:

        return await admin_service.update_classroom(id, data.model_dump(exclude_unset=True))

    except Exception as err:

        raise HTTPException(status_code=400, detail=str(err))

@router.delete("/classrooms/{id}")

async def delete_classroom(id: str, admin_service: AdminService = Depends()):

    try:

        await admin_service.delete_classroom(id)

        return {"status": "success"}

    except ValueError as err:

        raise HTTPException(status_code=400, detail=str(err))

    except Exception:

        raise HTTPException(status_code=500, detail="Internal server error")

@router.get("/designations", response_model=List[DesignationResponse])

async def get_designations(admin_service: AdminService = Depends()):

    return await admin_service.get_all_designations()

@router.get("/designations/{id}", response_model=DesignationResponse)

async def get_designation(id: str, admin_service: AdminService = Depends()):

    desig = await admin_service.get_designation_by_id(id)

    if not desig:

        raise HTTPException(status_code=404, detail="Designation not found")

    return desig

@router.post("/designations", response_model=DesignationResponse)

async def create_designation(data: DesignationCreate, admin_service: AdminService = Depends()):

    try:

        return await admin_service.create_designation(data.name, data.code, data.description)

    except Exception as err:

        raise HTTPException(status_code=400, detail=str(err))

@router.put("/designations/{id}", response_model=DesignationResponse)

async def update_designation(id: str, data: DesignationUpdate, admin_service: AdminService = Depends()):

    try:

        return await admin_service.update_designation(id, data.model_dump(exclude_unset=True))

    except Exception as err:

        raise HTTPException(status_code=400, detail=str(err))

@router.delete("/designations/{id}")

async def delete_designation(id: str, admin_service: AdminService = Depends()):

    try:

        await admin_service.delete_designation(id)

        return {"status": "success"}

    except ValueError as err:

        raise HTTPException(status_code=400, detail=str(err))

    except Exception:

        raise HTTPException(status_code=500, detail="Internal server error")

@router.get("/audit", response_model=List[AuditLogResponse])

async def get_audit_logs(admin_service: AdminService = Depends()):

    return await admin_service.get_audit_logs()

@router.get("/stats", response_model=AdminStatsResponse)

async def get_admin_stats(admin_service: AdminService = Depends()):

    return await admin_service.get_stats()

@router.post("/scan-absentees", status_code=status.HTTP_200_OK)

async def scan_absentee_anomalies(

    contamination: float = 0.10,

    attendance_repo: AttendanceRepository = Depends(),

) -> List[dict]:

    records = await attendance_repo.get_all_absences()

    if not records or len(records) < 5:

        return []

    rows = []

    for r in records:

        rows.append({

            "student_id": r.studentId,

            "status": r.status,

            "day_of_week": r.createdAt.strftime("%A")

        })

    try:

        flagged_students = await run_absentee_scan(attendance_records=rows, contamination=contamination)

        return flagged_students

    except Exception as err:

        raise HTTPException(

            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,

            detail=f"Outlier pattern extraction failed: {str(err)}"

        )

class Config:

    arbitrary_types_allowed = True

