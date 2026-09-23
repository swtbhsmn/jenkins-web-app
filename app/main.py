from datetime import datetime, timezone
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(
    title="FastAPI WebApp",
    description="FastAPI service with health check endpoint and Docker support",
    version="1.0.0",
)


class HealthResponse(BaseModel):
    status: str
    timestamp: str
    service: str

class UserResponse(BaseModel):
    status: str
    timestamp: str
    data: list[any]


@app.get("/", tags=["General"])
def read_root():
    return {"message": "Welcome to FastAPI WebApp"}


@app.get("/health", response_model=HealthResponse, tags=["Monitoring"])
def health_check():
    return HealthResponse(
        status="healthy",
        timestamp=datetime.now(timezone.utc).isoformat(),
        service="fastapi-webapp",
    )

@app.get("/users", response_model=HealthResponse, tags=["Monitoring"])
def get_users():
    return UserResponse(
        status="healthy",
        timestamp=datetime.now(timezone.utc).isoformat(),
        data=[{"name":"Swetabh"}]
    )