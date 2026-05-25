"""
Pydantic schemas for dispute management.
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class DisputeCreate(BaseModel):
    """Request schema for creating a dispute."""
    reason: str = Field(..., min_length=10, max_length=500, description="Reason for dispute (10-500 characters)")
    proof_image: Optional[str] = Field(None, description="Base64 encoded proof image or file path")


class DisputeResponse(BaseModel):
    """Response schema for dispute details."""
    id: str
    attendance_id: str
    student_id: str
    student_name: str
    enrollment_number: str
    class_name: str
    subject: str
    session_date: datetime
    original_status: str
    dispute_status: str
    dispute_reason: str
    proof_image_url: Optional[str]
    disputed_at: datetime
    resolved_at: Optional[datetime]
    teacher_remarks: Optional[str]
    
    model_config = ConfigDict(from_attributes=True)


class DisputeResolve(BaseModel):
    """Request schema for resolving a dispute."""
    status: str = Field(..., pattern="^(RESOLVED|REJECTED)$", description="Resolution status")
    remarks: str = Field(..., min_length=5, max_length=300, description="Teacher's resolution remarks")
    new_attendance_status: Optional[str] = Field(None, pattern="^(Present|Approved|Absent)$", description="New attendance status if approved")
