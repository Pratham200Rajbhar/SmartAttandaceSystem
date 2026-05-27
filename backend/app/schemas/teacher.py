from datetime import datetime
from typing import Optional, Literal

from pydantic import BaseModel, EmailStr, Field, ConfigDict


class TeacherCreate(BaseModel):
    email: EmailStr = Field(..., description="Unique email address of the teacher")
    password: str = Field(..., min_length=8, max_length=100, description="Secure account password")
    employee_id: str = Field(..., min_length=3, max_length=30, description="Unique employee identifier e.g. EMP2024001")
    first_name: str = Field(..., min_length=1, max_length=100, description="Teacher first name")
    last_name: str = Field(..., min_length=1, max_length=100, description="Teacher last name")
    department_id: str = Field(..., description="UUID of the teacher's department")
    designation_id: str = Field(..., description="UUID of the teacher's designation")
    phone: Optional[str] = Field(None, max_length=20, description="Contact phone number")
    qualification: Optional[str] = Field(None, max_length=100, description="Academic qualification e.g. Ph.D, M.Tech")
    specialization: Optional[str] = Field(None, max_length=100, description="Area of specialization e.g. Machine Learning")
    experience_years: Optional[int] = Field(None, ge=0, description="Years of professional experience")
    joining_date: Optional[datetime] = Field(None, description="Date of joining the institution")


class TeacherUpdate(BaseModel):
    employee_id: Optional[str] = Field(None, min_length=3, max_length=30)
    first_name: Optional[str] = Field(None, min_length=1, max_length=100)
    last_name: Optional[str] = Field(None, min_length=1, max_length=100)
    department_id: Optional[str] = Field(None)
    designation_id: Optional[str] = Field(None)
    phone: Optional[str] = Field(None, max_length=20)
    qualification: Optional[str] = Field(None, max_length=100)
    specialization: Optional[str] = Field(None, max_length=100)
    experience_years: Optional[int] = Field(None, ge=0)
    joining_date: Optional[datetime] = Field(None)


class TeacherResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str = Field(..., description="Unique UUID of the teacher record")
    user_id: str = Field(..., description="Mapped User UUID")
    email: str = Field(..., description="Email address associated with the user profile")
    employee_id: str = Field(..., description="Unique employee ID")
    first_name: str = Field(..., description="Teacher first name")
    last_name: str = Field(..., description="Teacher last name")
    department_id: str = Field(..., description="Raw department UUID")
    designation_id: str = Field(..., description="Raw designation UUID")
    department: str = Field(..., description="Resolved department name")
    designation: str = Field(..., description="Resolved designation name")
    phone: Optional[str] = Field(None, description="Contact phone number")
    qualification: Optional[str] = Field(None, description="Academic qualification")
    specialization: Optional[str] = Field(None, description="Area of specialization")
    experience_years: Optional[int] = Field(None, description="Years of professional experience")
    joining_date: Optional[datetime] = Field(None, description="Joining date")


class SessionStart(BaseModel):
    academic_class_id: str = Field(..., description="Target Class UUID for this session")
    duration_minutes: int = Field(10, ge=1, le=180, description="Session validity window in minutes")


class SessionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

    id: str = Field(..., description="Unique UUID of the active session")
    academic_class_id: str = Field(..., alias="academicClassId", description="Associated Class UUID")
    start_time: datetime = Field(..., alias="startTime", description="Timestamp when the session opened")
    end_time: datetime = Field(..., alias="endTime", description="Timestamp when the session will close")
    is_active: bool = Field(..., alias="isActive", description="Current state of the session")


class GeofenceUpsert(BaseModel):
    latitude: float = Field(..., description="GPS Latitude coordinate")
    longitude: float = Field(..., description="GPS Longitude coordinate")
    radius_meters: float = Field(..., gt=0.0, description="Geofence boundary radius in meters")


class GeofenceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

    id: str = Field(..., description="Unique UUID of the Geofence record")
    academic_class_id: str = Field(..., alias="academicClassId", description="Class ID")
    latitude: float = Field(..., description="Latitude coordinate")
    longitude: float = Field(..., description="Longitude coordinate")
    radius_meters: float = Field(..., alias="radiusMeters", description="Radius in meters")
    created_at: datetime = Field(..., alias="createdAt", description="Timestamp created")
    updated_at: datetime = Field(..., alias="updatedAt", description="Timestamp updated")


class AcademicClassWithGeofenceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

    id: str = Field(..., description="Unique UUID of the Academic Class")
    name: str = Field(..., description="Class name")
    subject: str = Field(..., description="Resolved subject name")
    teacher_id: str = Field(..., alias="teacherId", description="Teacher ID")
    geofence: Optional[GeofenceResponse] = Field(None, description="Class geofence configuration")


class StudentRosterItem(BaseModel):
    student_id: str = Field(..., description="Student UUID")
    enrollment_number: str = Field(..., description="Student enrollment number")
    full_name: str = Field(..., description="Student full name (first + last)")
    email: str = Field(..., description="Student email address")
    status: str = Field(..., description="Attendance status (Present, Flagged, Absent)")
    final_score: float = Field(..., description="Final calculated AI attendance score")
    marked_at: Optional[datetime] = Field(None, description="Timestamp attendance was registered")


class SessionAttendanceResponse(BaseModel):
    session_id: str = Field(..., description="Session UUID")
    class_name: str = Field(..., description="Class name")
    roster: list[StudentRosterItem] = Field(..., description="Enrolled roster list details")


class SessionTrendItem(BaseModel):
    session_id: str = Field(..., description="Session UUID")
    session_name: str = Field(..., description="Display name of session")
    attendance_percentage: float = Field(..., description="Attendance percentage for session")


class ClassStatsResponse(BaseModel):
    class_id: str = Field(..., description="Class UUID")
    total_sessions: int = Field(..., description="Total sessions held for class")
    total_students: int = Field(..., description="Total student count enrolled in class")
    overall_attendance_percentage: float = Field(..., description="Overall class attendance percentage")
    history: list[SessionTrendItem] = Field(default_factory=list, description="Chronological list of sessions with stats")


class AttendanceManualOverride(BaseModel):
    student_id: str = Field(..., description="Student UUID to override")
    status: str = Field(..., description="Target status (Present or Absent)")


class SessionWithClassResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

    id: str = Field(..., description="Unique UUID of the session")
    academic_class_id: str = Field(..., alias="academicClassId", description="Associated Class UUID")
    class_name: str = Field(..., description="Class Name")
    subject: str = Field(..., description="Resolved subject name")
    start_time: datetime = Field(..., alias="startTime", description="Timestamp when session opened")
    end_time: datetime = Field(..., alias="endTime", description="Timestamp when session closed")
    is_active: bool = Field(..., alias="isActive", description="Current state of session")


class BulkAttendanceRecord(BaseModel):
    student_id: str = Field(..., description="Student UUID")
    status: Literal["Present", "Absent"] = Field(..., description="Attendance status to set")


class BulkMarkRequest(BaseModel):
    records: list[BulkAttendanceRecord] = Field(..., min_length=1, description="List of student attendance records")


class AbsentStudentItem(BaseModel):
    student_id: str = Field(..., description="Student UUID")
    enrollment_number: str = Field(..., description="Student enrollment number")
    full_name: str = Field(..., description="Student full name")
    email: str = Field(..., description="Student email address")


class DeviceChangeResponse(BaseModel):
    id: str = Field(..., description="Device Change Request UUID")
    student_id: str = Field(..., description="Student UUID")
    student_name: str = Field(..., description="Student full name")
    enrollment_number: str = Field(..., description="Student enrollment number")
    new_device_uuid: str = Field(..., description="New device UUID requested")
    reason: Optional[str] = Field(None, description="Reason for device change")
    status: str = Field(..., description="Request status (PENDING, APPROVED, REJECTED)")
    approved_by: Optional[str] = Field(None, description="UUID of approver")
    created_at: datetime = Field(..., description="Creation timestamp")
    updated_at: datetime = Field(..., description="Last update timestamp")


class DeviceChangeApprove(BaseModel):
    status: Literal["APPROVED", "REJECTED"] = Field(..., description="Approval status decision")

