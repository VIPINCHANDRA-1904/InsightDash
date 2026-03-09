# InsightDash

**InsightDash** is a powerful, mobile-first dashboard application designed to instantly extract insights from raw logs and CSV datasets. It features a robust Python backend for high-performance data processing and a gorgeous, interactive Flutter frontend for a premium user experience.

## ✨ Features
- **Seamless Data Upload**: Upload raw logs, CSVs, and text files directly from your mobile device or web browser.
- **Smart Data Parsing**: The backend automatically reads your dataset, determines column structures, counts missing values, and computes statistical summaries (mean, sum, std, etc.).
- **Dynamic Interactive Visualization**: Enjoy beautifully rendered, animated bar charts and KPI metric summary cards.
- **FastAPI Powered Engine**: Lightning-fast, asynchronous Python backend using FastAPI, SQLAlchemy, and Pandas.
- **Cross-Platform**: Designed natively using Flutter, making the dashboard available to compile on Android, iOS, Windows, and Web.

## 🛠️ Technology Stack
- **Frontend**: Flutter, Dart, `fl_chart`
- **Backend**: Python, FastAPI, Pandas (data processing), Uvicorn
- **Database**: SQLite with SQLAlchemy ORM

## 🚀 Getting Started

### 1. Start the Backend
Navigate to the `backend` folder, set up your virtual environment, and boot up the FastAPI server:
```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install fastapi uvicorn pandas sqlalchemy python-multipart
uvicorn main:app --reload
```
The application backend will start up instantly at `http://127.0.0.1:8000`.

### 2. Start the Frontend
Navigate to the `frontend` directory and run the Flutter application:
```bash
cd frontend
flutter pub get
flutter run
```
*Note: If testing on an Android Emulator, ensure the API service URL in your Flutter configuration points to `http://10.0.2.2:8000` so it can properly route to your local host machine.*
