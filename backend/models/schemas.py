from pydantic import BaseModel
from datetime import datetime
from typing import Optional, Any, Dict

class FileResponse(BaseModel):
    id: int
    filename: str
    upload_time: datetime
    status: str
    file_size: int

    class Config:
        from_attributes = True

class AnalyticsResponse(BaseModel):
    id: int
    file_id: int
    total_rows: int
    total_columns: int
    columns_info: Dict[str, Any]
    summary_stats: Dict[str, Any]

    class Config:
        from_attributes = True

class StandardResponse(BaseModel):
    status: str
    data: Optional[Any] = None
    message: str
