from typing import List, Optional

from prisma.models import Department, AuditLog, Subject, Classroom, Designation

from app.core.security import hash_password
from app.db.client import db
from app.repositories.user_repo import UserRepository
from app.repositories.student_repo import StudentRepository
from app.repositories.teacher_repo import TeacherRepository
from app.repositories.class_repo import ClassRepository
from app.repositories.enrollment_repo import EnrollmentRepository
from app.schemas.student import StudentCreate, StudentResponse
from app.schemas.teacher import TeacherCreate, TeacherResponse
from app.schemas.admin import ClassCreate, ClassResponse


class AdminService:
    def __init__(self) -> None:
        self.user_repo = UserRepository()
        self.student_repo = StudentRepository()
        self.teacher_repo = TeacherRepository()
        self.class_repo = ClassRepository()
        self.enrollment_repo = EnrollmentRepository()

    @staticmethod
    async def _log_action(event_type: str, severity: str, actor: str, target: str, description: str, ip: Optional[str] = None) -> None:
        await db.auditlog.create(data={
            "eventType": event_type,
            "severity": severity,
            "actor": actor,
            "target": target,
            "description": description,
            "ip": ip,
        })

    # --- Students ---

    async def create_student(self, data: StudentCreate, actor: str = "system", ip: Optional[str] = None) -> StudentResponse:
        if data.department_id:
            if not await db.department.find_unique(where={"id": data.department_id}):
                raise ValueError("Department not found.")

        user = await db.user.create(data={
            "email": data.email, "hashedPassword": hash_password(data.password), "role": "STUDENT",
        })
        student = await db.student.create(
            data={k: v for k, v in {
                "userId": user.id, "enrollmentNumber": data.enrollment_number,
                "firstName": data.first_name, "lastName": data.last_name,
                "phone": data.phone, "gender": data.gender, "dateOfBirth": data.date_of_birth,
                "semester": data.semester, "batch": data.batch, "departmentId": data.department_id,
            }.items() if v is not None},
            include={"department": True},
        )
        await self._log_action("CREATE_STUDENT", "INFO", actor, student.id, f"Created student {data.email}", ip)
        return StudentResponse(
            id=student.id, user_id=user.id, enrollment_number=student.enrollmentNumber, email=user.email,
            first_name=student.firstName, last_name=student.lastName, phone=student.phone,
            gender=student.gender, date_of_birth=student.dateOfBirth,
            department_id=student.departmentId,
            department_name=student.department.name if student.department else None,
            semester=student.semester, batch=student.batch,
        )

    async def get_all_students(self) -> List[StudentResponse]:
        students = await db.student.find_many(include={"user": True, "department": True})
        return [
            StudentResponse(
                id=s.id, user_id=s.userId, enrollment_number=s.enrollmentNumber,
                email=s.user.email if s.user else "", first_name=s.firstName,
                last_name=s.lastName, phone=s.phone, gender=s.gender,
                date_of_birth=s.dateOfBirth, department_id=s.departmentId,
                department_name=s.department.name if s.department else None,
                semester=s.semester, batch=s.batch,
            )
            for s in students
        ]

    async def update_student(self, id: str, data: dict, actor: str = "system", ip: Optional[str] = None) -> StudentResponse:
        mapping = {
            "enrollment_number": "enrollmentNumber", "first_name": "firstName", "last_name": "lastName",
            "phone": "phone", "gender": "gender", "date_of_birth": "dateOfBirth",
            "semester": "semester", "batch": "batch", "department_id": "departmentId",
        }
        update_data = {mapping[k]: v for k, v in data.items() if k in mapping}
        student = await db.student.update(where={"id": id}, data=update_data, include={"user": True, "department": True})
        await self._log_action("UPDATE_STUDENT", "INFO", actor, id, f"Updated student {student.user.email if student.user else id}", ip)
        return StudentResponse(
            id=student.id, user_id=student.userId, enrollment_number=student.enrollmentNumber,
            email=student.user.email if student.user else "", first_name=student.firstName,
            last_name=student.lastName, phone=student.phone, gender=student.gender,
            date_of_birth=student.dateOfBirth, department_id=student.departmentId,
            department_name=student.department.name if student.department else None,
            semester=student.semester, batch=student.batch,
        )

    # --- Teachers ---

    async def create_teacher(self, data: TeacherCreate, actor: str = "system", ip: Optional[str] = None) -> TeacherResponse:
        if not await db.department.find_unique(where={"id": data.department_id}):
            raise ValueError(f"Department with id '{data.department_id}' not found.")
        if not await db.designation.find_unique(where={"id": data.designation_id}):
            raise ValueError(f"Designation with id '{data.designation_id}' not found.")

        user = await db.user.create(data={
            "email": data.email, "hashedPassword": hash_password(data.password), "role": "TEACHER",
        })
        teacher = await db.teacher.create(
            data={k: v for k, v in {
                "userId": user.id, "employeeId": data.employee_id,
                "firstName": data.first_name, "lastName": data.last_name,
                "departmentId": data.department_id, "designationId": data.designation_id,
                "phone": data.phone, "qualification": data.qualification,
                "specialization": data.specialization, "experienceYears": data.experience_years,
                "joiningDate": data.joining_date,
            }.items() if v is not None},
            include={"department": True, "designation": True},
        )
        await self._log_action("CREATE_TEACHER", "INFO", actor, teacher.id, f"Created teacher {data.email}", ip)
        return TeacherResponse(
            id=teacher.id, user_id=user.id, email=user.email, employee_id=teacher.employeeId,
            first_name=teacher.firstName, last_name=teacher.lastName,
            department_id=teacher.departmentId, designation_id=teacher.designationId,
            department=teacher.department.name, designation=teacher.designation.name,
            phone=teacher.phone, qualification=teacher.qualification,
            specialization=teacher.specialization, experience_years=teacher.experienceYears,
            joining_date=teacher.joiningDate,
        )

    async def get_all_teachers(self) -> List[TeacherResponse]:
        teachers = await db.teacher.find_many(include={"user": True, "department": True, "designation": True})
        return [
            TeacherResponse(
                id=t.id, user_id=t.userId, email=t.user.email if t.user else "",
                employee_id=t.employeeId, first_name=t.firstName, last_name=t.lastName,
                department_id=t.departmentId, designation_id=t.designationId,
                department=t.department.name if t.department else "",
                designation=t.designation.name if t.designation else "",
                phone=t.phone, qualification=t.qualification, specialization=t.specialization,
                experience_years=t.experienceYears, joining_date=t.joiningDate,
            )
            for t in teachers
        ]

    async def update_teacher(self, id: str, data: dict, actor: str = "system", ip: Optional[str] = None) -> TeacherResponse:
        mapping = {
            "employee_id": "employeeId", "first_name": "firstName", "last_name": "lastName",
            "department_id": "departmentId", "designation_id": "designationId", "phone": "phone",
            "qualification": "qualification", "specialization": "specialization",
            "experience_years": "experienceYears", "joining_date": "joiningDate",
        }
        update_data = {mapping[k]: v for k, v in data.items() if k in mapping}
        teacher = await db.teacher.update(where={"id": id}, data=update_data, include={"user": True, "department": True, "designation": True})
        await self._log_action("UPDATE_TEACHER", "INFO", actor, id, f"Updated teacher {teacher.user.email if teacher.user else id}", ip)
        return TeacherResponse(
            id=teacher.id, user_id=teacher.userId, email=teacher.user.email if teacher.user else "",
            employee_id=teacher.employeeId, first_name=teacher.firstName, last_name=teacher.lastName,
            department_id=teacher.departmentId, designation_id=teacher.designationId,
            department=teacher.department.name if teacher.department else "",
            designation=teacher.designation.name if teacher.designation else "",
            phone=teacher.phone, qualification=teacher.qualification,
            specialization=teacher.specialization, experience_years=teacher.experienceYears,
            joining_date=teacher.joiningDate,
        )

    # --- Classes ---

    async def create_class(self, data: ClassCreate, actor: str = "system", ip: Optional[str] = None) -> ClassResponse:
        if not await self.teacher_repo.get_by_id(data.teacher_id):
            raise ValueError("Teacher profile not found.")
        if not await db.subject.find_unique(where={"id": data.subject_id}):
            raise ValueError(f"Subject with id '{data.subject_id}' not found.")
        if data.classroom_id and not await db.classroom.find_unique(where={"id": data.classroom_id}):
            raise ValueError(f"Classroom with id '{data.classroom_id}' not found.")

        cls = await db.academicclass.create(
            data={k: v for k, v in {
                "name": data.name, "teacherId": data.teacher_id, "subjectId": data.subject_id,
                "classroomId": data.classroom_id, "semester": data.semester,
                "batch": data.batch, "maxStudents": data.max_students,
            }.items() if v is not None},
            include={"subject": True, "classroom": True, "enrollments": True},
        )
        await self._log_action("CREATE_CLASS", "INFO", actor, cls.id, f"Created class {data.name}", ip)
        return ClassResponse(
            id=cls.id, name=cls.name, subject_name=cls.subject.name, subject_code=cls.subject.code,
            teacherId=cls.teacherId, classroom_name=cls.classroom.name if cls.classroom else None,
            semester=cls.semester, batch=cls.batch, max_students=cls.maxStudents,
            enrolled_count=len(cls.enrollments) if cls.enrollments else 0,
            enrolled_student_ids=[e.studentId for e in cls.enrollments] if cls.enrollments else [],
        )

    async def get_all_classes(self) -> List[ClassResponse]:
        classes = await db.academicclass.find_many(include={"subject": True, "classroom": True, "enrollments": True})
        return [
            ClassResponse(
                id=c.id, name=c.name, subject_name=c.subject.name if c.subject else "",
                subject_code=c.subject.code if c.subject else "", teacherId=c.teacherId,
                classroom_name=c.classroom.name if c.classroom else None,
                semester=c.semester, batch=c.batch, max_students=c.maxStudents,
                enrolled_count=len(c.enrollments) if c.enrollments else 0,
                enrolled_student_ids=[e.studentId for e in c.enrollments] if c.enrollments else [],
            )
            for c in classes
        ]

    async def update_class(self, class_id: str, data: dict, actor: str = "system", ip: Optional[str] = None) -> ClassResponse:
        renames = {"subject_id": "subjectId", "classroom_id": "classroomId", "teacher_id": "teacherId"}
        for old, new in renames.items():
            if old in data:
                data[new] = data.pop(old)
        cls = await db.academicclass.update(where={"id": class_id}, data=data, include={"subject": True, "classroom": True, "enrollments": True})
        await self._log_action("UPDATE_CLASS", "INFO", actor, class_id, f"Updated class {cls.name}", ip)
        return ClassResponse(
            id=cls.id, name=cls.name, subject_name=cls.subject.name if cls.subject else "",
            subject_code=cls.subject.code if cls.subject else "", teacherId=cls.teacherId,
            classroom_name=cls.classroom.name if cls.classroom else None,
            semester=cls.semester, batch=cls.batch, max_students=cls.maxStudents,
            enrolled_count=len(cls.enrollments) if cls.enrollments else 0,
            enrolled_student_ids=[e.studentId for e in cls.enrollments] if cls.enrollments else [],
        )

    async def assign_teacher(self, class_id: str, teacher_id: str, actor: str = "system", ip: Optional[str] = None) -> ClassResponse:
        if not await self.class_repo.get_by_id(class_id):
            raise ValueError("Academic class not found.")
        if not await self.teacher_repo.get_by_id(teacher_id):
            raise ValueError("Teacher profile not found.")
        cls = await db.academicclass.update(where={"id": class_id}, data={"teacherId": teacher_id}, include={"subject": True, "classroom": True, "enrollments": True})
        await self._log_action("ASSIGN_TEACHER", "INFO", actor, class_id, f"Assigned teacher {teacher_id} to class {cls.name}", ip)
        return ClassResponse(
            id=cls.id, name=cls.name, subject_name=cls.subject.name if cls.subject else "",
            subject_code=cls.subject.code if cls.subject else "", teacherId=cls.teacherId,
            classroom_name=cls.classroom.name if cls.classroom else None,
            semester=cls.semester, batch=cls.batch, max_students=cls.maxStudents,
            enrolled_count=len(cls.enrollments) if cls.enrollments else 0,
            enrolled_student_ids=[e.studentId for e in cls.enrollments] if cls.enrollments else [],
        )

    async def enroll_students(self, class_id: str, student_ids: List[str], actor: str = "system", ip: Optional[str] = None) -> int:
        if not await self.class_repo.get_by_id(class_id):
            raise ValueError("Academic class not found.")
        count = 0
        for sid in student_ids:
            if await self.student_repo.get_by_id(sid):
                existing = await db.enrollment.find_first(
                    where={"studentId": sid, "academicClassId": class_id}
                )
                if not existing:
                    await self.enrollment_repo.enroll_student(sid, class_id)
                    count += 1
        await self._log_action("ENROLL_STUDENTS", "INFO", actor, class_id, f"Enrolled {count} student(s) in class", ip)
        return count

    # --- Master Data Helpers ---

    @staticmethod
    async def _validate_delete(entity_name: str, record, ref_field: str, ref_table_name: str):
        if not record:
            raise ValueError(f"{entity_name} not found.")
        ref_count = await getattr(db, ref_table_name).count(where={ref_field: record.id})
        if ref_count > 0:
            raise ValueError(f"Cannot delete {entity_name.lower()} because it is currently assigned.")

    # --- Departments ---

    async def get_all_departments(self) -> List[Department]:
        return await db.department.find_many()

    async def get_department_by_id(self, id: str) -> Optional[Department]:
        return await db.department.find_unique(where={"id": id})

    async def create_department(self, name: str, code: str, head: Optional[str] = None, description: Optional[str] = None) -> Department:
        return await db.department.create(data={"name": name, "code": code, "head": head, "description": description})

    async def update_department(self, id: str, data: dict) -> Department:
        return await db.department.update(where={"id": id}, data=data)

    async def delete_department(self, id: str, actor: str = "system", ip: Optional[str] = None) -> None:
        dept = await db.department.find_unique(where={"id": id})
        await self._validate_delete("Department", dept, "departmentId", "teacher")
        await self._validate_delete("Department", dept, "departmentId", "student")
        await db.department.delete(where={"id": id})
        await self._log_action("DELETE_DEPARTMENT", "WARNING", actor, id, f"Deleted department {dept.name if dept else id}", ip)

    # --- Subjects ---

    async def get_all_subjects(self) -> List[Subject]:
        return await db.subject.find_many()

    async def get_subject_by_id(self, id: str) -> Optional[Subject]:
        return await db.subject.find_unique(where={"id": id})

    async def create_subject(self, name: str, code: str, description: Optional[str] = None) -> Subject:
        return await db.subject.create(data={"name": name, "code": code, "description": description})

    async def update_subject(self, id: str, data: dict) -> Subject:
        return await db.subject.update(where={"id": id}, data=data)

    async def delete_subject(self, id: str, actor: str = "system", ip: Optional[str] = None) -> None:
        sub = await db.subject.find_unique(where={"id": id})
        await self._validate_delete("Subject", sub, "subjectId", "academicclass")
        await db.subject.delete(where={"id": id})
        await self._log_action("DELETE_SUBJECT", "WARNING", actor, id, f"Deleted subject {sub.name if sub else id}", ip)

    # --- Classrooms ---

    async def get_all_classrooms(self) -> List[Classroom]:
        return await db.classroom.find_many()

    async def get_classroom_by_id(self, id: str) -> Optional[Classroom]:
        return await db.classroom.find_unique(where={"id": id})

    async def create_classroom(self, name: str, building: Optional[str] = None, capacity: Optional[int] = None) -> Classroom:
        return await db.classroom.create(data={"name": name, "building": building, "capacity": capacity})

    async def update_classroom(self, id: str, data: dict) -> Classroom:
        return await db.classroom.update(where={"id": id}, data=data)

    async def delete_classroom(self, id: str, actor: str = "system", ip: Optional[str] = None) -> None:
        classroom = await db.classroom.find_unique(where={"id": id})
        await self._validate_delete("Classroom", classroom, "classroomId", "academicclass")
        await db.classroom.delete(where={"id": id})
        await self._log_action("DELETE_CLASSROOM", "WARNING", actor, id, f"Deleted classroom {classroom.name if classroom else id}", ip)

    # --- Designations ---

    async def get_all_designations(self) -> List[Designation]:
        return await db.designation.find_many()

    async def get_designation_by_id(self, id: str) -> Optional[Designation]:
        return await db.designation.find_unique(where={"id": id})

    async def create_designation(self, name: str, code: str, description: Optional[str] = None) -> Designation:
        return await db.designation.create(data={"name": name, "code": code, "description": description})

    async def update_designation(self, id: str, data: dict) -> Designation:
        return await db.designation.update(where={"id": id}, data=data)

    async def delete_designation(self, id: str, actor: str = "system", ip: Optional[str] = None) -> None:
        desig = await db.designation.find_unique(where={"id": id})
        await self._validate_delete("Designation", desig, "designationId", "teacher")
        await db.designation.delete(where={"id": id})
        await self._log_action("DELETE_DESIGNATION", "WARNING", actor, id, f"Deleted designation {desig.name if desig else id}", ip)

    # --- Misc ---

    async def get_audit_logs(self) -> List[AuditLog]:
        return await db.auditlog.find_many(order={"timestamp": "desc"})

    async def get_stats(self) -> dict:
        return {
            "studentCount": await db.student.count(),
            "teacherCount": await db.teacher.count(),
            "classCount": await db.academicclass.count(),
        }

    async def reset_user_password(self, user_id: str, new_password: str, actor: str = "system", ip: Optional[str] = None) -> None:
        if not await db.user.find_unique(where={"id": user_id}):
            raise ValueError("User not found.")
        await db.user.update(where={"id": user_id}, data={"hashedPassword": hash_password(new_password)})
        await self._log_action("RESET_PASSWORD", "WARNING", actor, user_id, "Reset user password", ip)
