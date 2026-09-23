aws_region            = "us-east-1"
repository_name       = "fastapi-webapp"
image_tag_mutability  = "MUTABLE"
scan_on_push          = true
force_delete          = false
image_retention_count = 30
tags = {
  Environment = "production"
  Project     = "fastapi-webapp"
  ManagedBy   = "terraform"
}

