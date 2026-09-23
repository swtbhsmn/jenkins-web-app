aws_region            = "us-east-1"
repository_name       = "fastapi-webapp"
image_tag_mutability  = "MUTABLE"
scan_on_push          = true
force_delete          = false
image_retention_count = 30

# ECS and ALB Configuration
ecs_cluster_name      = "fastapi-cluster"
ecs_service_name      = "fastapi-service"
app_port              = 8000
app_count             = 1
fargate_cpu           = 256
fargate_memory        = 512
health_check_path     = "/health"
log_retention_in_days = 7

tags = {
  Environment = "production"
  Project     = "fastapi-webapp"
  ManagedBy   = "terraform"
}

