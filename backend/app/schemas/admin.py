from typing import List, Optional
from pydantic import BaseModel, Field, ConfigDict


class ClassCreate(BaseModel):
    """Payload to create a new academic class with FK-linked subject and optional classroom."""

    name: str = Field(..., min_length=2, max_length=100, description="Name of the class e.g. CS-101-A")
    subject_id: str = Field(..., description="UUID of the linked Subject")
    teacher_id: str = Field(..., min_length=36, max_length=36, description="UUID of the associated Teacher profile")
    classroom_id: Optional[str] = Field(None, description="UUID of the assigned Classroom (optional)")
    semester: Optional[int] = Field(None, ge=1, le=8, description="Academic semester (1–8)")
    batch: Optional[str] = Field(None, max_length=20, description="Batch year range e.g. 2022-2026")
    max_students: Optional[int] = Field(None, ge=1, description="Maximum student capacity for the class")


class ClassUpdate(BaseModel):
    """Partial update payload for an academic class."""

    name: Optional[str] = Field(None, min_length=2, max_length=100)
    subject_id: Optional[str] = Field(None)
    teacher_id: Optional[str] = Field(None, min_length=36, max_length=36)
    classroom_id: Optional[str] = Field(None)
    semester: Optional[int] = Field(None, ge=1, le=8)
    batch: Optional[str] = Field(None, max_length=20)
    max_students: Optional[int] = Field(None, ge=1)


class AssignTeacherRequest(BaseModel):
    """Payload to reassign the teacher of an existing class."""

    teacher_id: str = Field(..., min_length=36, max_length=36, description="UUID of the Teacher profile to assign")


class EnrollRequest(BaseModel):
    """Payload to enroll one or more students into a class."""

    student_ids: List[str] = Field(..., min_length=1, description="List of Student UUIDs to enroll in the class")


class ClassResponse(BaseModel):
    """Full class record returned to admin clients with resolved FK display names."""

    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

    id: str = Field(..., description="Unique UUID of the Academic Class")
    name: str = Field(..., description="Name of the class")
    subject_name: str = Field(..., description="Resolved subject name")
    subject_code: str = Field(..., description="Resolved subject code")
    teacher_id: str = Field(..., alias="teacherId", description="Teacher ID associated with this class")
    classroom_name: Optional[str] = Field(None, description="Resolved classroom name")
    semester: Optional[int] = Field(None, description="Academic semester")
    batch: Optional[str] = Field(None, description="Batch year range")
    max_students: Optional[int] = Field(None, description="Maximum student capacity")
    enrolled_count: int = Field(0, description="Current number of enrolled students")


class DepartmentCreate(BaseModel):
    """Payload to create a new department."""

    name: str = Field(..., min_length=3, max_length=100)
    code: str = Field(..., min_length=2, max_length=10)
    head: Optional[str] = None
    description: Optional[str] = None


class DepartmentUpdate(BaseModel):
    """Partial update payload for a department."""

    name: Optional[str] = Field(None, min_length=3, max_length=100)
    code: Optional[str] = Field(None, min_length=2, max_length=10)
    head: Optional[str] = None
    description: Optional[str] = None


class DepartmentResponse(BaseModel):
    """Public-facing department record."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    code: str
    head: Optional[str] = None
    description: Optional[str] = None
    classCount: int = 0


class AuditLogResponse(BaseModel):
    """A single audit log entry."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    timestamp: str
    eventType: str
    severity: str
    actor: str
    target: str
    description: str
    ip: Optional[str] = None
    meta: Optional[dict] = None


class AdminStatsResponse(BaseModel):
    """Dashboard-level statistics for the admin."""

    studentCount: int
    teacherCount: int
    classCount: int

class AdminResetPasswordRequest(BaseModel):
    """Payload for admin to forcefully reset a user's password."""
    new_password: str = Field(..., min_length=8, description="New password for the user")
