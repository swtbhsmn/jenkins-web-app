variable "aws_region" {
  description = "The AWS region where the ECR repository will be created"
  type        = string
  default     = "us-east-1"
}

variable "repository_name" {
  description = "The name of the ECR repository"
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

variable "tags" {
  description = "A mapping of tags to assign to the resources"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "fastapi-webapp"
    ManagedBy   = "terraform"
  }
}

