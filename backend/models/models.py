from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from database import Base

class UploadedFile(Base):
    __tablename__ = "uploaded_files"

    id = Column(Integer, primary_key=True, index=True)
    filename = Column(String, index=True)
    upload_time = Column(DateTime, default=datetime.utcnow)
    file_path = Column(String)
    file_size = Column(Integer)
    status = Column(String, default="uploaded") # uploaded, processing, completed, error
    
    analytics = relationship("AnalyticsResult", back_populates="file", cascade="all, delete", uselist=False)

class AnalyticsResult(Base):
    __tablename__ = "analytics_results"

    id = Column(Integer, primary_key=True, index=True)
    file_id = Column(Integer, ForeignKey("uploaded_files.id"))
    total_rows = Column(Integer)
    total_columns = Column(Integer)
    columns_info = Column(Text) # JSON string
    summary_stats = Column(Text) # JSON string
    created_at = Column(DateTime, default=datetime.utcnow)

    file = relationship("UploadedFile", back_populates="analytics")
