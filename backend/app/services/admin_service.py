from typing import List, Optional
from app.repositories.user_repo import UserRepository
from app.repositories.student_repo import StudentRepository
from app.repositories.teacher_repo import TeacherRepository
from app.repositories.class_repo import ClassRepository
from app.repositories.enrollment_repo import EnrollmentRepository
from app.core.security import hash_password
from app.schemas.student import StudentCreate, StudentResponse
from app.schemas.teacher import TeacherCreate, TeacherResponse
from app.schemas.admin import ClassCreate, ClassUpdate, ClassResponse
from prisma.models import AcademicClass, Enrollment, Department, AuditLog, Subject, Classroom, Designation
from app.db.client import db


class AdminService:
    """Service layer for all admin-only operations.

    Handles student/teacher/class CRUD and master-data management.
    All business-logic validation (FK existence, in-use guards) lives here.
    """

    def __init__(self) -> None:
        self.user_repo = UserRepository()
        self.student_repo = StudentRepository()
        self.teacher_repo = TeacherRepository()
        self.class_repo = ClassRepository()
        self.enrollment_repo = EnrollmentRepository()

    # ------------------------------------------------------------------ #
    # Student management
    # ------------------------------------------------------------------ #

    async def create_student(self, data: StudentCreate) -> StudentResponse:
        """Create a new student User + Student profile.

        Validates department FK if provided, then creates the user and
        student records in sequence. Returns a fully populated response.
        """
        if data.department_id:
            dept = await db.department.find_unique(where={"id": data.department_id})
            if not dept:
                raise ValueError("Department not found.")

        hashed = hash_password(data.password)
        user = await db.user.create(
            data={
                "email": data.email,
                "hashedPassword": hashed,
                "role": "STUDENT",
            }
        )

        create_data: dict = {
            "userId": user.id,
            "enrollmentNumber": data.enrollment_number,
            "firstName": data.first_name,
            "lastName": data.last_name,
        }
        if data.phone is not None:
            create_data["phone"] = data.phone
        if data.gender is not None:
            create_data["gender"] = data.gender
        if data.date_of_birth is not None:
            create_data["dateOfBirth"] = data.date_of_birth
        if data.semester is not None:
            create_data["semester"] = data.semester
        if data.batch is not None:
            create_data["batch"] = data.batch
        if data.department_id is not None:
            create_data["departmentId"] = data.department_id

        student = await db.student.create(
            data=create_data,
            include={"department": True},
        )

        return StudentResponse(
            id=student.id,
            user_id=user.id,
            enrollment_number=student.enrollmentNumber,
            email=user.email,
            first_name=student.firstName,
            last_name=student.lastName,
            phone=student.phone,
            gender=student.gender,
            date_of_birth=student.dateOfBirth,
            department_id=student.departmentId,
            department_name=student.department.name if student.department else None,
            semester=student.semester,
            batch=student.batch,
            device_reset_requested=student.deviceResetRequested,
        )

    async def get_all_students(self) -> List[StudentResponse]:
        """Return all student records with resolved department names."""
        students = await db.student.find_many(
            include={"user": True, "department": True}
        )
        return [
            StudentResponse(
                id=s.id,
                user_id=s.userId,
                enrollment_number=s.enrollmentNumber,
                email=s.user.email if s.user else "",
                first_name=s.firstName,
                last_name=s.lastName,
                phone=s.phone,
                gender=s.gender,
                date_of_birth=s.dateOfBirth,
                department_id=s.departmentId,
                department_name=s.department.name if s.department else None,
                semester=s.semester,
                batch=s.batch,
                device_reset_requested=s.deviceResetRequested,
            )
            for s in students
        ]

    async def update_student(self, id: str, data: dict) -> StudentResponse:
        """Partially update a student record and return the updated response."""
        update_data = {}
        if "enrollment_number" in data: update_data["enrollmentNumber"] = data["enrollment_number"]
        if "first_name" in data: update_data["firstName"] = data["first_name"]
        if "last_name" in data: update_data["lastName"] = data["last_name"]
        if "phone" in data: update_data["phone"] = data["phone"]
        if "gender" in data: update_data["gender"] = data["gender"]
        if "date_of_birth" in data: update_data["dateOfBirth"] = data["date_of_birth"]
        if "semester" in data: update_data["semester"] = data["semester"]
        if "batch" in data: update_data["batch"] = data["batch"]
        if "department_id" in data: update_data["departmentId"] = data["department_id"]

        student = await db.student.update(
            where={"id": id},
            data=update_data,
            include={"user": True, "department": True},
        )
        return StudentResponse(
            id=student.id,
            user_id=student.userId,
            enrollment_number=student.enrollmentNumber,
            email=student.user.email if student.user else "",
            first_name=student.firstName,
            last_name=student.lastName,
            phone=student.phone,
            gender=student.gender,
            date_of_birth=student.dateOfBirth,
            department_id=student.departmentId,
            department_name=student.department.name if student.department else None,
            semester=student.semester,
            batch=student.batch,
            device_reset_requested=student.deviceResetRequested,
        )

    # ------------------------------------------------------------------ #
    # Teacher management
    # ------------------------------------------------------------------ #

    async def create_teacher(self, data: TeacherCreate) -> TeacherResponse:
        """Create a new teacher User + Teacher profile.

        Validates both department_id and designation_id FK references before
        creating any records to avoid partial-create states.
        """
        dept = await db.department.find_unique(where={"id": data.department_id})
        if not dept:
            raise ValueError(f"Department with id '{data.department_id}' not found.")

        desig = await db.designation.find_unique(where={"id": data.designation_id})
        if not desig:
            raise ValueError(f"Designation with id '{data.designation_id}' not found.")

        hashed = hash_password(data.password)
        user = await db.user.create(
            data={
                "email": data.email,
                "hashedPassword": hashed,
                "role": "TEACHER",
            }
        )

        teacher_data: dict = {
            "userId": user.id,
            "employeeId": data.employee_id,
            "firstName": data.first_name,
            "lastName": data.last_name,
            "departmentId": data.department_id,
            "designationId": data.designation_id,
        }
        if data.phone is not None:
            teacher_data["phone"] = data.phone
        if data.qualification is not None:
            teacher_data["qualification"] = data.qualification
        if data.specialization is not None:
            teacher_data["specialization"] = data.specialization
        if data.experience_years is not None:
            teacher_data["experienceYears"] = data.experience_years
        if data.joining_date is not None:
            teacher_data["joiningDate"] = data.joining_date

        teacher = await db.teacher.create(
            data=teacher_data,
            include={"department": True, "designation": True},
        )

        return TeacherResponse(
            id=teacher.id,
            user_id=user.id,
            email=user.email,
            employee_id=teacher.employeeId,
            first_name=teacher.firstName,
            last_name=teacher.lastName,
            department_id=teacher.departmentId,
            designation_id=teacher.designationId,
            department=teacher.department.name,
            designation=teacher.designation.name,
            phone=teacher.phone,
            qualification=teacher.qualification,
            specialization=teacher.specialization,
            experience_years=teacher.experienceYears,
            joining_date=teacher.joiningDate,
        )

    async def get_all_teachers(self) -> List[TeacherResponse]:
        """Return all teacher records with resolved department and designation names."""
        teachers = await db.teacher.find_many(
            include={"user": True, "department": True, "designation": True}
        )
        return [
            TeacherResponse(
                id=t.id,
                user_id=t.userId,
                email=t.user.email if t.user else "",
                employee_id=t.employeeId,
                first_name=t.firstName,
                last_name=t.lastName,
                department_id=t.departmentId,
                designation_id=t.designationId,
                department=t.department.name if t.department else "",
                designation=t.designation.name if t.designation else "",
                phone=t.phone,
                qualification=t.qualification,
                specialization=t.specialization,
                experience_years=t.experienceYears,
                joining_date=t.joiningDate,
            )
            for t in teachers
        ]

    async def update_teacher(self, id: str, data: dict) -> TeacherResponse:
        """Partially update a teacher profile.

        Maps incoming snake_case FK field names to the camelCase prisma field names.
        """
        update_data = {}
        if "employee_id" in data: update_data["employeeId"] = data["employee_id"]
        if "first_name" in data: update_data["firstName"] = data["first_name"]
        if "last_name" in data: update_data["lastName"] = data["last_name"]
        if "department_id" in data: update_data["departmentId"] = data["department_id"]
        if "designation_id" in data: update_data["designationId"] = data["designation_id"]
        if "phone" in data: update_data["phone"] = data["phone"]
        if "qualification" in data: update_data["qualification"] = data["qualification"]
        if "specialization" in data: update_data["specialization"] = data["specialization"]
        if "experience_years" in data: update_data["experienceYears"] = data["experience_years"]
        if "joining_date" in data: update_data["joiningDate"] = data["joining_date"]

        teacher = await db.teacher.update(
            where={"id": id},
            data=update_data,
            include={"user": True, "department": True, "designation": True},
        )
        return TeacherResponse(
            id=teacher.id,
            user_id=teacher.userId,
            email=teacher.user.email if teacher.user else "",
            employee_id=teacher.employeeId,
            first_name=teacher.firstName,
            last_name=teacher.lastName,
            department_id=teacher.departmentId,
            designation_id=teacher.designationId,
            department=teacher.department.name if teacher.department else "",
            designation=teacher.designation.name if teacher.designation else "",
            phone=teacher.phone,
            qualification=teacher.qualification,
            specialization=teacher.specialization,
            experience_years=teacher.experienceYears,
            joining_date=teacher.joiningDate,
        )

    # ------------------------------------------------------------------ #
    # Class management
    # ------------------------------------------------------------------ #

    async def create_class(self, data: ClassCreate) -> ClassResponse:
        """Create a new academic class with FK-linked subject and optional classroom.

        Validates teacher, subject, and classroom FKs before creating.
        """
        teacher = await self.teacher_repo.get_by_id(data.teacher_id)
        if not teacher:
            raise ValueError("Teacher profile not found.")

        subject = await db.subject.find_unique(where={"id": data.subject_id})
        if not subject:
            raise ValueError(f"Subject with id '{data.subject_id}' not found.")

        if data.classroom_id:
            classroom = await db.classroom.find_unique(where={"id": data.classroom_id})
            if not classroom:
                raise ValueError(f"Classroom with id '{data.classroom_id}' not found.")

        create_data: dict = {
            "name": data.name,
            "teacherId": data.teacher_id,
            "subjectId": data.subject_id,
        }
        if data.classroom_id is not None:
            create_data["classroomId"] = data.classroom_id
        if data.semester is not None:
            create_data["semester"] = data.semester
        if data.batch is not None:
            create_data["batch"] = data.batch
        if data.max_students is not None:
            create_data["maxStudents"] = data.max_students

        cls = await db.academicclass.create(
            data=create_data,
            include={"subject": True, "classroom": True, "enrollments": True},
        )

        return ClassResponse(
            id=cls.id,
            name=cls.name,
            subject_name=cls.subject.name,
            subject_code=cls.subject.code,
            teacherId=cls.teacherId,
            classroom_name=cls.classroom.name if cls.classroom else None,
            semester=cls.semester,
            batch=cls.batch,
            max_students=cls.maxStudents,
            enrolled_count=len(cls.enrollments) if cls.enrollments else 0,
        )

    async def get_all_classes(self) -> List[ClassResponse]:
        """Return all academic classes with resolved subject, classroom, and enrollment count."""
        classes = await db.academicclass.find_many(
            include={"subject": True, "classroom": True, "enrollments": True}
        )
        return [
            ClassResponse(
                id=c.id,
                name=c.name,
                subject_name=c.subject.name if c.subject else "",
                subject_code=c.subject.code if c.subject else "",
                teacherId=c.teacherId,
                classroom_name=c.classroom.name if c.classroom else None,
                semester=c.semester,
                batch=c.batch,
                max_students=c.maxStudents,
                enrolled_count=len(c.enrollments) if c.enrollments else 0,
            )
            for c in classes
        ]

    async def update_class(self, class_id: str, data: dict) -> ClassResponse:
        """Partially update a class record, remapping FK field names."""
        if "subject_id" in data:
            data["subjectId"] = data.pop("subject_id")
        if "classroom_id" in data:
            data["classroomId"] = data.pop("classroom_id")
        if "teacher_id" in data:
            data["teacherId"] = data.pop("teacher_id")

        cls = await db.academicclass.update(
            where={"id": class_id},
            data=data,
            include={"subject": True, "classroom": True, "enrollments": True},
        )
        return ClassResponse(
            id=cls.id,
            name=cls.name,
            subject_name=cls.subject.name if cls.subject else "",
            subject_code=cls.subject.code if cls.subject else "",
            teacherId=cls.teacherId,
            classroom_name=cls.classroom.name if cls.classroom else None,
            semester=cls.semester,
            batch=cls.batch,
            max_students=cls.maxStudents,
            enrolled_count=len(cls.enrollments) if cls.enrollments else 0,
        )

    async def assign_teacher(self, class_id: str, teacher_id: str) -> ClassResponse:
        """Reassign the teacher of an existing class."""
        academic_class = await self.class_repo.get_by_id(class_id)
        if not academic_class:
            raise ValueError("Academic class not found.")

        teacher = await self.teacher_repo.get_by_id(teacher_id)
        if not teacher:
            raise ValueError("Teacher profile not found.")

        cls = await db.academicclass.update(
            where={"id": class_id},
            data={"teacherId": teacher_id},
            include={"subject": True, "classroom": True, "enrollments": True},
        )
        return ClassResponse(
            id=cls.id,
            name=cls.name,
            subject_name=cls.subject.name if cls.subject else "",
            subject_code=cls.subject.code if cls.subject else "",
            teacherId=cls.teacherId,
            classroom_name=cls.classroom.name if cls.classroom else None,
            semester=cls.semester,
            batch=cls.batch,
            max_students=cls.maxStudents,
            enrolled_count=len(cls.enrollments) if cls.enrollments else 0,
        )

    async def enroll_students(self, class_id: str, student_ids: List[str]) -> int:
        """Enroll a list of students into a class. Returns the count enrolled."""
        academic_class = await self.class_repo.get_by_id(class_id)
        if not academic_class:
            raise ValueError("Academic class not found.")

        count = 0
        for student_id in student_ids:
            student = await self.student_repo.get_by_id(student_id)
            if student:
                await self.enrollment_repo.enroll_student(student.id, class_id)
                count += 1
        return count

    # ------------------------------------------------------------------ #
    # Department CRUD
    # ------------------------------------------------------------------ #

    async def get_all_departments(self) -> List[Department]:
        """Return all departments."""
        return await db.department.find_many()

    async def get_department_by_id(self, id: str) -> Optional[Department]:
        """Return a single department by its UUID."""
        return await db.department.find_unique(where={"id": id})

    async def create_department(
        self,
        name: str,
        code: str,
        head: Optional[str] = None,
        description: Optional[str] = None,
    ) -> Department:
        """Create a new department."""
        return await db.department.create(
            data={"name": name, "code": code, "head": head, "description": description}
        )

    async def update_department(self, id: str, data: dict) -> Department:
        """Partially update a department."""
        return await db.department.update(where={"id": id}, data=data)

    async def delete_department(self, id: str) -> None:
        """Delete a department, guarded by FK count check.

        Uses the FK relation (departmentId) instead of string matching so the
        guard is accurate regardless of how names are stored.
        """
        dept = await db.department.find_unique(where={"id": id})
        if not dept:
            raise ValueError("Department not found.")

        teacher_count = await db.teacher.count(where={"departmentId": id})
        if teacher_count > 0:
            raise ValueError(
                "Cannot delete department because it is currently assigned to one or more teachers."
            )

        student_count = await db.student.count(where={"departmentId": id})
        if student_count > 0:
            raise ValueError(
                "Cannot delete department because it is currently assigned to one or more students."
            )

        await db.department.delete(where={"id": id})

    # ------------------------------------------------------------------ #
    # Subject CRUD
    # ------------------------------------------------------------------ #

    async def get_all_subjects(self) -> List[Subject]:
        """Return all subjects."""
        return await db.subject.find_many()

    async def get_subject_by_id(self, id: str) -> Optional[Subject]:
        """Return a single subject by its UUID."""
        return await db.subject.find_unique(where={"id": id})

    async def create_subject(
        self, name: str, code: str, description: Optional[str] = None
    ) -> Subject:
        """Create a new subject."""
        return await db.subject.create(
            data={"name": name, "code": code, "description": description}
        )

    async def update_subject(self, id: str, data: dict) -> Subject:
        """Partially update a subject."""
        return await db.subject.update(where={"id": id}, data=data)

    async def delete_subject(self, id: str) -> None:
        """Delete a subject, guarded by FK count check."""
        sub = await db.subject.find_unique(where={"id": id})
        if not sub:
            raise ValueError("Subject not found.")

        class_count = await db.academicclass.count(where={"subjectId": id})
        if class_count > 0:
            raise ValueError(
                "Cannot delete subject because it is currently assigned to one or more academic classes."
            )

        await db.subject.delete(where={"id": id})

    # ------------------------------------------------------------------ #
    # Classroom CRUD
    # ------------------------------------------------------------------ #

    async def get_all_classrooms(self) -> List[Classroom]:
        """Return all classrooms."""
        return await db.classroom.find_many()

    async def get_classroom_by_id(self, id: str) -> Optional[Classroom]:
        """Return a single classroom by its UUID."""
        return await db.classroom.find_unique(where={"id": id})

    async def create_classroom(
        self,
        name: str,
        building: Optional[str] = None,
        capacity: Optional[int] = None,
    ) -> Classroom:
        """Create a new classroom."""
        return await db.classroom.create(
            data={"name": name, "building": building, "capacity": capacity}
        )

    async def update_classroom(self, id: str, data: dict) -> Classroom:
        """Partially update a classroom."""
        return await db.classroom.update(where={"id": id}, data=data)

    async def delete_classroom(self, id: str) -> None:
        """Delete a classroom, guarded by FK count check."""
        classroom = await db.classroom.find_unique(where={"id": id})
        if not classroom:
            raise ValueError("Classroom not found.")

        class_count = await db.academicclass.count(where={"classroomId": id})
        if class_count > 0:
            raise ValueError(
                "Cannot delete classroom because it is currently assigned to one or more classes."
            )

        await db.classroom.delete(where={"id": id})

    # ------------------------------------------------------------------ #
    # Designation CRUD
    # ------------------------------------------------------------------ #

    async def get_all_designations(self) -> List[Designation]:
        """Return all designations."""
        return await db.designation.find_many()

    async def get_designation_by_id(self, id: str) -> Optional[Designation]:
        """Return a single designation by its UUID."""
        return await db.designation.find_unique(where={"id": id})

    async def create_designation(
        self, name: str, code: str, description: Optional[str] = None
    ) -> Designation:
        """Create a new designation."""
        return await db.designation.create(
            data={"name": name, "code": code, "description": description}
        )

    async def update_designation(self, id: str, data: dict) -> Designation:
        """Partially update a designation."""
        return await db.designation.update(where={"id": id}, data=data)

    async def delete_designation(self, id: str) -> None:
        """Delete a designation, guarded by FK count check."""
        desig = await db.designation.find_unique(where={"id": id})
        if not desig:
            raise ValueError("Designation not found.")

        teacher_count = await db.teacher.count(where={"designationId": id})
        if teacher_count > 0:
            raise ValueError(
                "Cannot delete designation because it is currently assigned to one or more teachers."
            )

        await db.designation.delete(where={"id": id})

    # ------------------------------------------------------------------ #
    # Audit & stats
    # ------------------------------------------------------------------ #

    async def get_audit_logs(self) -> List[AuditLog]:
        """Return all audit logs ordered by most recent first."""
        return await db.auditlog.find_many(order={"timestamp": "desc"})

    async def get_stats(self) -> dict:
        """Return summary counts for the admin dashboard."""
        student_count = await db.student.count()
        teacher_count = await db.teacher.count()
        class_count = await db.academicclass.count()
        return {
            "studentCount": student_count,
            "teacherCount": teacher_count,
            "classCount": class_count,
        }

    async def reset_user_password(self, user_id: str, new_password: str) -> None:
        """Forcefully reset a user's password."""
        user = await db.user.find_unique(where={"id": user_id})
        if not user:
            raise ValueError("User not found.")
        
        hashed = hash_password(new_password)
        await db.user.update(
            where={"id": user_id},
            data={"hashedPassword": hashed}
        )
