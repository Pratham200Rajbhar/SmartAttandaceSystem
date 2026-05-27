from datetime import datetime, date
from typing import Optional

from pydantic import BaseModel, Field, field_validator, ConfigDict


class LeaveRequestCreate(BaseModel):
    start_date: date = Field(..., description="Leave start date")
    end_date: date = Field(..., description="Leave end date")
    reason: str = Field(..., min_length=10, max_length=500, description="Reason for leave")
    document_url: Optional[str] = Field(None, description="Supporting document URL (medical certificate, etc.)")

    @field_validator('end_date')
    @classmethod
    def validate_date_range(cls, v, info):
        if 'start_date' in info.data and v < info.data['start_date']:
            raise ValueError('end_date must be after or equal to start_date')
        return v


class LeaveRequestResponse(BaseModel):
    id: str
    student_id: str
    student_name: str
    enrollment_number: str
    start_date: datetime
    end_date: datetime
    reason: str
    document_url: Optional[str]
    status: str
    approved_by: Optional[str]
    approver_note: Optional[str]
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class LeaveRequestApprove(BaseModel):
    status: str = Field(..., pattern="^(APPROVED|REJECTED)$", description="Approval status")
    approver_note: Optional[str] = Field(None, max_length=300, description="Optional note from approver")


class LeaveRequestListResponse(BaseModel):
    leaves: list[LeaveRequestResponse]
    total: int
    pending: int
    approved: int
    rejected: int
