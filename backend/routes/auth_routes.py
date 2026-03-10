from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import timedelta

from database import get_db
from models import models, schemas
from auth import get_password_hash, verify_password, create_access_token, get_current_user

router = APIRouter()

@router.post("/register", response_model=schemas.StandardResponse)
def register_user(user_in: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.username == user_in.username).first()
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already registered"
        )
    
    new_user = models.User(
        username=user_in.username,
        hashed_password=get_password_hash(user_in.password)
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return schemas.StandardResponse(
        status="success",
        data=schemas.UserResponse.model_validate(new_user),
        message="User registered successfully"
    )

@router.post("/login", response_model=schemas.StandardResponse)
def login_user(login_data: schemas.LoginRequest, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.username == login_data.username).first()
    if not user or not verify_password(login_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token = create_access_token(data={"user_id": user.id})
    
    return schemas.StandardResponse(
        status="success",
        data={
            "access_token": access_token,
            "token_type": "bearer",
            "user": schemas.UserResponse.model_validate(user)
        },
        message="Login successful"
    )

@router.get("/me", response_model=schemas.StandardResponse)
def get_me(current_user: models.User = Depends(get_current_user)):
    return schemas.StandardResponse(
        status="success",
        data=schemas.UserResponse.model_validate(current_user),
        message="User details retrieved"
    )
