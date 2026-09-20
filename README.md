# FastAPI WebApp with Health Endpoint

A lightweight FastAPI service featuring a structured `/health` endpoint, Docker containerization, and Docker Compose orchestration.

---

## Project Structure

```
webapp/
├── app/
│   ├── __init__.py
│   └── main.py          # FastAPI application & /health endpoint
├── tests/
│   ├── __init__.py
│   └── test_health.py   # Automated pytest suite
├── .dockerignore
├── Dockerfile           # Production container build with healthcheck
├── docker-compose.yml   # Multi-container orchestration & service definition
├── requirements.txt     # Dependencies
└── README.md
```

---

## API Endpoints

| Method | Endpoint | Description | Sample Response |
|---|---|---|---|
| `GET` | `/` | Root index / welcome message | `{"message": "Welcome to FastAPI WebApp"}` |
| `GET` | `/health` | Service health status and timestamp | `{"status": "healthy", "timestamp": "...", "service": "fastapi-webapp"}` |
| `GET` | `/docs` | Interactive Swagger API documentation | Swagger UI |
| `GET` | `/redoc` | Interactive ReDoc documentation | ReDoc UI |

---

## Quick Commands (Makefile)

| Command | Description |
|---|---|
| `make help` | Show all available targets |
| `make up` | Build & start container stack in background |
| `make down` | Stop container stack |
| `make restart` | Rebuild and restart container stack |
| `make logs` | Follow container logs |
| `make ps` | View container & health status |
| `make health` | Query `/health` endpoint via curl |
| `make test` | Run test suite |
| `make run` | Run FastAPI locally with reload |
| `make clean` | Remove bytecode and cached artifacts |

---

## Running with Docker Compose (Recommended)

Make sure Docker is running (e.g. start Docker Desktop on macOS).

1. **Build and start container**:
   ```bash
   docker compose up -d --build
   ```

2. **Check service and container health status**:
   ```bash
   docker compose ps
   ```

3. **Test the health endpoint**:
   ```bash
   curl http://localhost:8000/health
   ```

4. **View logs**:
   ```bash
   docker compose logs -f
   ```

5. **Stop containers**:
   ```bash
   docker compose down
   ```

---

## Running with Standalone Docker

1. **Build the image**:
   ```bash
   docker build -t fastapi-webapp .
   ```

2. **Run container**:
   ```bash
   docker run -d -p 8000:8000 --name fastapi-app fastapi-webapp
   ```

3. **Check health status**:
   ```bash
   docker inspect --format='{{json .State.Health.Status}}' fastapi-app
   ```

4. **Stop and remove**:
   ```bash
   docker stop fastapi-app && docker rm fastapi-app
   ```

---

## Running Locally

1. **Activate virtual environment & install dependencies**:
   ```bash
   source .venv/bin/activate
   pip install -r requirements.txt
   ```

2. **Run the server**:
   ```bash
   uvicorn app.main:app --reload --port 8000
   ```

3. **Run automated tests**:
   ```bash
   pytest tests/
   ```

