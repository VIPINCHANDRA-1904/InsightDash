import pytest
from fastapi.testclient import TestClient
from main import app
import os
import io

client = TestClient(app)

def test_health_check():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"status": "success", "message": "InsightDash API is running"}

def test_upload_log_file():
    # Create dummy csv file content
    dummy_csv = "id,name,value\n1,Test_A,10\n2,Test_B,20\n3,Test_C,30\n"
    
    file_payload = {
        "file": ("test_log.csv", io.BytesIO(dummy_csv.encode("utf-8")), "text/csv")
    }
    
    response = client.post("/api/upload/upload/", files=file_payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert data["data"]["filename"] == "test_log.csv"
    assert "id" in data["data"]
    
    # Optional: check if file appears in get_files
    response_files = client.get("/api/upload/files/")
    assert response_files.status_code == 200
    files_data = response_files.json()
    assert len(files_data["data"]) > 0
