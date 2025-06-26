variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "todo-app"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "todo-app.example.com"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "postgres"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "todo_app_production"
}

variable "jwt_secret_key" {
  description = "JWT secret key for Rails"
  type        = string
  sensitive   = true
  default     = null
}

variable "rails_master_key" {
  description = "Rails master key"
  type        = string
  sensitive   = true
  default     = null
}

variable "frontend_image_tag" {
  description = "Frontend Docker image tag"
  type        = string
  default     = "latest"
}

variable "backend_image_tag" {
  description = "Backend Docker image tag"
  type        = string
  default     = "latest"
}

locals {
  jwt_secret_key = var.jwt_secret_key != null ? var.jwt_secret_key : (
    try(nonsensitive(data.aws_ssm_parameter.jwt_secret_key[0].value),
    "dummy-jwt-secret-key-for-development")
  )

  rails_master_key = var.rails_master_key != null ? var.rails_master_key : (
    try(nonsensitive(data.aws_ssm_parameter.rails_master_key[0].value),
    "dummy-rails-master-key-for-development")
  )
}

data "aws_ssm_parameter" "jwt_secret_key" {
  count = var.jwt_secret_key == null ? 1 : 0
  name  = "/${var.project_name}/${var.environment}/jwt_secret_key"
}

data "aws_ssm_parameter" "rails_master_key" {
  count = var.rails_master_key == null ? 1 : 0
  name  = "/${var.project_name}/${var.environment}/rails_master_key"
}
