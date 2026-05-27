from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field, ConfigDict


class StudentCreate(BaseModel):
    email: EmailStr = Field(..., description="Unique email address of the student")
    password: str = Field(..., min_length=8, max_length=100, description="Secure account password")
    enrollment_number: str = Field(..., min_length=5, max_length=30, description="University Enrollment Number")
    first_name: str = Field(..., min_length=1, max_length=100, description="Student first name")
    last_name: str = Field(..., min_length=1, max_length=100, description="Student last name")
    phone: Optional[str] = Field(None, max_length=20, description="Contact phone number")
    gender: Optional[str] = Field(None, description="Gender identity")
    date_of_birth: Optional[datetime] = Field(None, description="Date of birth")
    semester: Optional[int] = Field(None, ge=1, le=8, description="Current academic semester (1–8)")
    batch: Optional[str] = Field(None, max_length=20, description="Batch year range e.g. 2022-2026")
    department_id: Optional[str] = Field(None, description="UUID of the student's department")


class StudentUpdate(BaseModel):
    enrollment_number: Optional[str] = Field(None, min_length=5, max_length=30)
    first_name: Optional[str] = Field(None, min_length=1, max_length=100)
    last_name: Optional[str] = Field(None, min_length=1, max_length=100)
    phone: Optional[str] = Field(None, max_length=20)
    gender: Optional[str] = Field(None)
    date_of_birth: Optional[datetime] = Field(None)
    semester: Optional[int] = Field(None, ge=1, le=8)
    batch: Optional[str] = Field(None, max_length=20)
    department_id: Optional[str] = Field(None)


class StudentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str = Field(..., description="Unique UUID of the student record")
    user_id: str = Field(..., description="Mapped User UUID")
    enrollment_number: str = Field(..., description="Student enrollment number")
    email: str = Field(..., description="Email address associated with the user profile")
    first_name: Optional[str] = Field(None, description="Student first name")
    last_name: Optional[str] = Field(None, description="Student last name")
    phone: Optional[str] = Field(None, description="Contact phone number")
    gender: Optional[str] = Field(None, description="Gender identity")
    date_of_birth: Optional[datetime] = Field(None, description="Date of birth")
    department_id: Optional[str] = Field(None, description="Raw department UUID")
    department_name: Optional[str] = Field(None, description="Resolved department name")
    semester: Optional[int] = Field(None, description="Current semester")
    batch: Optional[str] = Field(None, description="Batch year range")


class StudentAttendanceItem(BaseModel):
    attendance_id: str = Field(..., description="UUID of attendance record")
    class_id: str = Field(..., description="Class UUID")
    class_name: str = Field(..., description="Class name")
    subject: str = Field(..., description="Subject name")
    session_id: str = Field(..., description="Session UUID")
    status: str = Field(..., description="Attendance status (Present, Flagged, Absent)")
    marked_at: datetime = Field(..., description="Timestamp marked")
    face_score: Optional[float] = Field(None, description="AI face similarity score")
    liveness_score: Optional[float] = Field(None, description="AI liveness score")
    background_score: Optional[float] = Field(None, description="AI background score")
    final_ai_score: Optional[float] = Field(None, description="Composite AI score")
    teacher_note: Optional[str] = Field(None, description="Teacher review note/remarks")


class StudentAttendanceHistoryResponse(BaseModel):
    student_id: str = Field(..., description="Student profile UUID")
    overall_attendance_percentage: float = Field(..., description="Overall attendance percentage over all enrolled courses")
    history: list[StudentAttendanceItem] = Field(..., description="Detailed history itemized logs")


class StudentClassResponse(BaseModel):
    class_id: str = Field(..., description="Class UUID")
    class_name: str = Field(..., description="Class name")
    subject: str = Field(..., description="Subject name")
    teacher_name: str = Field(..., description="Teacher name")
    active_session_id: Optional[str] = Field(None, description="UUID of active session if any")
    session_end_time: Optional[datetime] = Field(None, description="Active session end time if any")
    latitude: Optional[float] = Field(None, description="Geofence center latitude")
    longitude: Optional[float] = Field(None, description="Geofence center longitude")
    radius_meters: Optional[float] = Field(None, description="Geofence radius in meters")
