.PHONY: help install run test up down restart logs ps health docker-build clean

PYTHON ?= python3
VENV ?= .venv

help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Install Python dependencies into virtual environment
	$(VENV)/bin/pip install -r requirements.txt

run: ## Run FastAPI server locally with auto-reload
	$(VENV)/bin/uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

test: ## Run automated unit tests
	$(VENV)/bin/python -m unittest discover -s tests -p "test_*.py"

up: ## Build and start services in detached mode with Docker Compose
	docker compose up -d --build

down: ## Stop and remove containers created by Docker Compose
	docker compose down

restart: ## Restart Docker Compose services
	docker compose down && docker compose up -d --build

logs: ## View live logs from Docker Compose
	docker compose logs -f

ps: ## View running containers and health status
	docker compose ps

health: ## Check health endpoint via curl
	@curl -s -i http://localhost:8000/health

docker-build: ## Build standalone Docker image
	docker build -t fastapi-webapp .

clean: ## Clean up Python cache and temporary files
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	rm -rf .pytest_cache .coverage htmlcov

