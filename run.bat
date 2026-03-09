@echo off
echo Starting InsightDash Backend...
cd backend
start cmd /k "venv\Scripts\activate.bat && python main.py"
echo Backend started on http://127.0.0.1:8000
echo.
echo Starting InsightDash Frontend (Web)...
cd ../frontend
start cmd /k "flutter run -d chrome"
echo Setup complete.
