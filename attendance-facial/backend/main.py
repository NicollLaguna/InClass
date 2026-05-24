from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from config import settings
from routes import attendance, reports
from routes.auth import router as auth_router
from routes.courses import router as courses_router
from routes.enrollments import router as enrollments_router
from routes.sessions import router as sessions_router
from routes.students import router as students_router
from services.notification_service import init_firebase

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="API para control de asistencia mediante reconocimiento facial",
    swagger_ui_parameters={"persistAuthorization": True},
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup_event():
    init_firebase()

app.include_router(auth_router)
app.include_router(courses_router)
app.include_router(enrollments_router)
app.include_router(sessions_router)
app.include_router(students_router)
app.include_router(attendance.router)
app.include_router(reports.router)

@app.get("/")
async def root():
    return {
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "online"
    }


if __name__ == "__main__":
    import uvicorn, os
    uvicorn.run("main:app", host="0.0.0.0", port=int(os.getenv("PORT", 8000)))