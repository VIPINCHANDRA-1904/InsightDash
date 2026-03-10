from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Optional, Any, List, Dict

class UserBase(BaseModel):
    username: str

class UserCreate(UserBase):
    password: str

class UserResponse(UserBase):
    id: int
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)

class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse

class LoginRequest(BaseModel):
    username: str
    password: str

class FileResponse(BaseModel):
    id: int
    filename: str
    upload_time: datetime
    status: str
    file_size: int
    model_config = ConfigDict(from_attributes=True)

class AnalyticsResponse(BaseModel):
    id: int
    file_id: int
    total_rows: int
    total_columns: int
    columns_info: Dict[str, Any]
    summary_stats: Dict[str, Any]
    model_config = ConfigDict(from_attributes=True)

class StandardResponse(BaseModel):
    status: str
    data: Optional[Any] = None
    message: str
