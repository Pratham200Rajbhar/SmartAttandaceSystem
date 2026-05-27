from pydantic import BaseModel, Field, ConfigDict



class SubjectCreate(BaseModel):
    name: str = Field(..., min_length=3, max_length=100)
    code: str = Field(..., min_length=2, max_length=10)
    description: str | None = None


class SubjectUpdate(BaseModel):
    name: str | None = Field(None, min_length=3, max_length=100)
    code: str | None = Field(None, min_length=2, max_length=10)
    description: str | None = None


class SubjectResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    code: str
    description: str | None = None


class ClassroomCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    building: str | None = None
    capacity: int | None = Field(None, ge=1)


class ClassroomUpdate(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=100)
    building: str | None = None
    capacity: int | None = Field(None, ge=1)


class ClassroomResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    building: str | None = None
    capacity: int | None = None


class DesignationCreate(BaseModel):
    name: str = Field(..., min_length=3, max_length=100)
    code: str = Field(..., min_length=2, max_length=10)
    description: str | None = None


class DesignationUpdate(BaseModel):
    name: str | None = Field(None, min_length=3, max_length=100)
    code: str | None = Field(None, min_length=2, max_length=10)
    description: str | None = None


class DesignationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    code: str
    description: str | None = None
