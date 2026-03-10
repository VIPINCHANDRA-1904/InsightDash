import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging

from database import engine
from models import models
from routes import upload, analytics, auth_routes

# Create local db structure
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="InsightDash API",
    description="Backend for Mobile-First Dashboard Application",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # For development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_routes.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(upload.router, prefix="/api/upload", tags=["Upload"])
app.include_router(analytics.router, prefix="/api/analytics", tags=["Analytics"])

@app.get("/", tags=["Health"])
def health_check():
    return {"status": "success", "message": "InsightDash API is running"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
