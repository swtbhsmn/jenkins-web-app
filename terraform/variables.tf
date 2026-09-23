variable "aws_region" {
  description = "The AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "repository_name" {
  description = "The name of the ECR repository and container"
  type        = string
  default     = "fastapi-webapp"
}

variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository"
  type        = bool
  default     = true
}

variable "force_delete" {
  description = "If true, deleting the repository will force deletion even if it contains images"
  type        = bool
  default     = false
}

variable "image_retention_count" {
  description = "The maximum number of images to retain in the repository"
  type        = number
  default     = 30
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
  default     = "fastapi-cluster"
}

variable "ecs_service_name" {
  description = "The name of the ECS service"
  type        = string
  default     = "fastapi-service"
}

variable "app_port" {
  description = "Port exposed by the FastAPI container"
  type        = number
  default     = 8000
}

variable "app_count" {
  description = "Number of docker containers to run"
  type        = number
  default     = 1
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  type        = number
  default     = 256
}

variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  type        = number
  default     = 512
}

variable "health_check_path" {
  description = "HTTP health check path for the Application Load Balancer"
  type        = string
  default     = "/health"
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "A mapping of tags to assign to the resources"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "fastapi-webapp"
    ManagedBy   = "terraform"
  }
}
