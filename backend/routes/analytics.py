import json
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
import pandas as pd
import os

from database import get_db
from models import models, schemas

from auth import get_current_user

router = APIRouter()

@router.get("/{file_id}/summary", response_model=schemas.StandardResponse)
def get_analytics_summary(file_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    file_record = db.query(models.UploadedFile).filter(
        models.UploadedFile.id == file_id,
        models.UploadedFile.user_id == current_user.id
    ).first()
    
    if not file_record:
        raise HTTPException(status_code=404, detail="File not found or access denied")
        
    if file_record.status != "completed":
        raise HTTPException(status_code=400, detail=f"File status is {file_record.status}")
        
    analytics = db.query(models.AnalyticsResult).filter(models.AnalyticsResult.file_id == file_id).first()
    if not analytics:
        raise HTTPException(status_code=404, detail="Analytics not found for this file.")
        
    return schemas.StandardResponse(
        status="success",
        data={
            "id": analytics.id,
            "file_id": analytics.file_id,
            "total_rows": analytics.total_rows,
            "total_columns": analytics.total_columns,
            "columns_info": json.loads(analytics.columns_info),
            "summary_stats": json.loads(analytics.summary_stats)
        },
        message="Analytics retrieved successfully"
    )

@router.get("/{file_id}/dataset", response_model=schemas.StandardResponse)
def get_processed_dataset(file_id: int, skip: int = 0, limit: int = 100, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    file_record = db.query(models.UploadedFile).filter(
        models.UploadedFile.id == file_id,
        models.UploadedFile.user_id == current_user.id
    ).first()
    
    if not file_record:
        raise HTTPException(status_code=404, detail="File not found or access denied")
        
    if not os.path.exists(file_record.file_path):
        raise HTTPException(status_code=404, detail="Physical file not found on server")

    try:
        if file_record.file_path.endswith('.csv'):
            df = pd.read_csv(file_record.file_path, skiprows=range(1, skip + 1), nrows=limit)
        elif file_record.file_path.endswith('.json'):
            df = pd.read_json(file_record.file_path)
            df = df.iloc[skip:skip+limit]
        else:
            try:
                df = pd.read_csv(file_record.file_path, sep=None, engine='python', skiprows=range(1, skip + 1), nrows=limit)
            except Exception:
                df = pd.read_csv(file_record.file_path, sep='\t', names=['log_line'], skiprows=skip, nrows=limit, on_bad_lines='skip')
                
        records = df.to_dict(orient="records")
        return schemas.StandardResponse(
            status="success",
            data=records,
            message="Dataset retrieved successfully"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error reading dataset: {str(e)}")

@router.get("/{file_id}/chart", response_model=schemas.StandardResponse)
def get_chart_data(file_id: int, column: str, chart_type: str = "bar", limit: int = 10, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    file_record = db.query(models.UploadedFile).filter(
        models.UploadedFile.id == file_id,
        models.UploadedFile.user_id == current_user.id
    ).first()
    
    if not file_record:
        raise HTTPException(status_code=404, detail="File not found or access denied")

    if not os.path.exists(file_record.file_path):
        raise HTTPException(status_code=404, detail="Physical file not found on server")
        
    try:
        # We need to compute frequency for the column
        # Read the file
        if file_record.file_path.endswith('.csv'):
            df = pd.read_csv(file_record.file_path, usecols=[column])
        else:
            df = pd.read_csv(file_record.file_path, sep=None, engine='python', usecols=[column])
            
        counts = df[column].value_counts().head(limit).to_dict()
        chart_data = [{"label": str(k), "value": float(v)} for k, v in counts.items()]
        
        return schemas.StandardResponse(
            status="success",
            data={"chart_type": chart_type, "column": column, "data": chart_data},
            message="Chart data retrieved successfully"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating chart data: {str(e)}")
