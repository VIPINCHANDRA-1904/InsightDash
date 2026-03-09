import os
import shutil
from fastapi import APIRouter, File, UploadFile, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
import json

from database import SessionLocal, get_db
from models import models, schemas
from services.log_processor import process_log_file

router = APIRouter()

UPLOAD_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', 'uploads'))
os.makedirs(UPLOAD_DIR, exist_ok=True)

def parse_and_store_analytics(file_id: int, file_path: str):
    db = SessionLocal()
    try:
        db_file = db.query(models.UploadedFile).filter(models.UploadedFile.id == file_id).first()
        if not db_file:
            return
            
        db_file.status = "processing"
        db.commit()
        
        # process
        result = process_log_file(file_path)
        
        # store
        analytics = models.AnalyticsResult(
            file_id=file_id,
            total_rows=result["total_rows"],
            total_columns=result["total_columns"],
            columns_info=json.dumps(result["columns_info"]),
            summary_stats=json.dumps(result["summary_stats"])
        )
        db.add(analytics)
        
        db_file.status = "completed"
        db.commit()
    except Exception as e:
        db_file = db.query(models.UploadedFile).filter(models.UploadedFile.id == file_id).first()
        if db_file:
            db_file.status = "error"
            db.commit()
    finally:
        db.close()

@router.post("/upload/", response_model=schemas.StandardResponse)
async def upload_log_file(
    background_tasks: BackgroundTasks, 
    file: UploadFile = File(...), 
    db: Session = Depends(get_db)):
    
    file_path = os.path.join(UPLOAD_DIR, file.filename)
    
    # Save the file
    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to upload file: {str(e)}")
        
    file_size = os.path.getsize(file_path)

    # Save details to DB
    new_file = models.UploadedFile(
        filename=file.filename,
        file_path=file_path,
        file_size=file_size,
        status="uploaded"
    )
    db.add(new_file)
    db.commit()
    db.refresh(new_file)
    
    # trigger background task
    background_tasks.add_task(parse_and_store_analytics, new_file.id, file_path)
    
    return schemas.StandardResponse(
        status="success",
        data={"id": new_file.id, "filename": new_file.filename, "status": new_file.status},
        message="File uploaded successfully and formatting in background."
    )

@router.get("/files/", response_model=schemas.StandardResponse)
def get_files(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    files = db.query(models.UploadedFile).offset(skip).limit(limit).all()
    file_list = []
    for f in files:
        file_list.append({
            "id": f.id,
            "filename": f.filename,
            "upload_time": str(f.upload_time),
            "status": f.status,
            "file_size": f.file_size
        })
    return schemas.StandardResponse(
        status="success",
        data=file_list,
        message="Retrieved successfully"
    )
