from typing import Optional

from pydantic import BaseModel, EmailStr, Field


class UserLogin(BaseModel):
    email: EmailStr = Field(..., description="Unique email address of the user")
    password: str = Field(..., min_length=8, max_length=100, description="Plaintext password")
    device_uuid: Optional[str] = Field(None, description="Hardware device UUID for student device binding")


class Token(BaseModel):
    access_token: str = Field(..., description="Signed JWT access token")
    token_type: str = Field("bearer", description="Token protocol type")
    role: str = Field(..., description="Role of the authenticated user (STUDENT, TEACHER, ADMIN)")


class UserProfileResponse(BaseModel):
    id: str = Field(..., description="Unique UUID of the user")
    email: EmailStr = Field(..., description="Email address of the user")
    role: str = Field(..., description="Assigned role of the user")
    is_active: bool = Field(..., description="System status flag")
    student_profile: Optional[dict] = Field(None, description="Detailed student profile if role is STUDENT")
    teacher_profile: Optional[dict] = Field(None, description="Detailed teacher profile if role is TEACHER")


class DeviceChangeRequestCreate(BaseModel):
    email: EmailStr = Field(..., description="Unique email address of the user")
    password: str = Field(..., min_length=8, max_length=100, description="Plaintext password")
    new_device_uuid: str = Field(..., description="The new hardware device UUID")
    reason: Optional[str] = Field(None, description="Optional reason for changing the device")
