variable "project_name" {
  description = "Lowercase project identifier."
  type        = string
  default     = "nestforge"
}

variable "environment" {
  description = "Environment safety boundary. This root only accepts dev."
  type        = string
  default     = "dev"

  validation {
    condition     = var.environment == "dev"
    error_message = "The dev root can only manage the dev environment."
  }
}

variable "aws_region" {
  description = "AWS region used by the dev environment."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "Dev VPC IPv4 CIDR."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Dev public subnet CIDRs."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "Dev private application subnet CIDRs."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "Dev private database subnet CIDRs."
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "availability_zones" {
  description = "Optional explicit AZ pair; empty selects the first two available AZs dynamically."
  type        = list(string)
  default     = []
}

variable "image_tag" {
  description = "Immutable ECR image tag to deploy."
  type        = string
  default     = "manual-bootstrap"
}

variable "certificate_arn" {
  description = "Optional ACM certificate ARN. Null enables temporary HTTP-only access."
  type        = string
  default     = null
  nullable    = true
}

variable "enable_http_listener" {
  description = "Enable HTTP forwarding or redirect."
  type        = bool
  default     = true
}

variable "task_cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Fargate task memory in MiB."
  type        = number
  default     = 1024
}

variable "ecs_desired_count" {
  description = "Initial dev task count."
  type        = number
  default     = 1
}

variable "ecs_min_capacity" {
  description = "Dev ECS autoscaling minimum."
  type        = number
  default     = 1
}

variable "ecs_max_capacity" {
  description = "Dev ECS autoscaling maximum."
  type        = number
  default     = 3
}

variable "ecs_cpu_target" {
  description = "Average ECS CPU target percentage."
  type        = number
  default     = 65
}

variable "enable_container_insights" {
  description = "Enable ECS Container Insights."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Dev CloudWatch log retention."
  type        = number
  default     = 14
}

variable "database_engine_version" {
  description = "RDS PostgreSQL major version."
  type        = string
  default     = "17"
}

variable "database_instance_class" {
  description = "Dev RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "database_allocated_storage" {
  description = "Initial dev RDS gp3 storage in GiB."
  type        = number
  default     = 20
}

variable "database_max_allocated_storage" {
  description = "Maximum dev RDS autoscaled storage in GiB."
  type        = number
  default     = 100
}

variable "database_multi_az" {
  description = "Enable Multi-AZ RDS in dev."
  type        = bool
  default     = false
}

variable "database_backup_retention_period" {
  description = "Dev automated backup retention in days."
  type        = number
  default     = 7
}

variable "database_deletion_protection" {
  description = "Enable RDS deletion protection in dev."
  type        = bool
  default     = false
}

variable "database_skip_final_snapshot" {
  description = "Skip final RDS snapshot in dev."
  type        = bool
  default     = true
}

variable "database_ssl_reject_unauthorized" {
  description = "Verify the RDS TLS certificate chain from NestJS."
  type        = bool
  default     = true
}

variable "secret_recovery_window_in_days" {
  description = "Dev secret recovery window; zero force-deletes during teardown."
  type        = number
  default     = 0
}

variable "alb_deletion_protection" {
  description = "Enable ALB deletion protection in dev."
  type        = bool
  default     = false
}
