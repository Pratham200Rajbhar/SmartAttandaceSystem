from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class AttendanceMarkResponse(BaseModel):


    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

    id: str = Field(..., description="Unique UUID of the attendance record")
    student_id: str = Field(..., validation_alias="studentId", description="Student UUID")
    session_id: str = Field(..., validation_alias="sessionId", description="Session UUID")
    status: str = Field(..., description="Outcome of the weighted decision: 'Present' or 'Flagged'")
    face_score: float = Field(..., validation_alias="faceScore", description="AI Face similarity score (0.0 to 1.0)")
    liveness_score: float = Field(..., validation_alias="livenessScore", description="AI Face liveness score (0.0 to 1.0)")
    background_score: float = Field(..., validation_alias="backgroundScore", description="AI Background learning-environment score (0.0 to 1.0)")
    final_ai_score: float = Field(..., validation_alias="finalAiScore", description="Composite decision engine score (0.0 to 1.0)")
    gps_latitude: float = Field(..., validation_alias="gpsLatitude", description="Submitted GPS Latitude")
    gps_longitude: float = Field(..., validation_alias="gpsLongitude", description="Submitted GPS Longitude")
    created_at: datetime = Field(..., validation_alias="createdAt", description="Verification timestamp")


class FlaggedAttendanceResponse(BaseModel):


    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

    id: str = Field(..., description="Attendance Record UUID")
    enrollment_number: str = Field(..., description="Student enrollment number")
    student_name: str = Field(..., description="Student full email or name context")
    class_name: str = Field(..., description="Class name")
    subject: str = Field(..., description="Course Subject")
    face_score: float = Field(..., validation_alias="faceScore", description="Similarity confidence")
    liveness_score: float = Field(..., validation_alias="livenessScore", description="Liveness confidence")
    background_score: float = Field(..., validation_alias="backgroundScore", description="Background confidence")
    final_ai_score: float = Field(..., validation_alias="finalAiScore", description="Composite engine decision score")
    gps_latitude: float = Field(..., validation_alias="gpsLatitude", description="Submitted GPS Latitude")
    gps_longitude: float = Field(..., validation_alias="gpsLongitude", description="Submitted GPS Longitude")
    created_at: datetime = Field(..., validation_alias="createdAt", description="Verification timestamp")


class AttendanceReview(BaseModel):


    status: str = Field(..., pattern="^(Approved|Rejected)$", description="Review decision: 'Approved' or 'Rejected'")
    remarks: Optional[str] = Field(default="", max_length=250, description="Audit notes/justification from the teacher")
