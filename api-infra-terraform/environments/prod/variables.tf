variable "project_name" {
  description = "Lowercase project identifier."
  type        = string
  default     = "nestforge"
}

variable "environment" {
  description = "Environment safety boundary. This root only accepts prod."
  type        = string
  default     = "prod"

  validation {
    condition     = var.environment == "prod"
    error_message = "The prod root can only manage the prod environment."
  }
}

variable "aws_region" {
  description = "AWS region used by the prod environment."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "Prod VPC IPv4 CIDR."
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Prod public subnet CIDRs."
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "Prod private application subnet CIDRs."
  type        = list(string)
  default     = ["10.1.11.0/24", "10.1.12.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "Prod private database subnet CIDRs."
  type        = list(string)
  default     = ["10.1.21.0/24", "10.1.22.0/24"]
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
  description = "Optional ACM certificate ARN. Null permits temporary HTTP-only access."
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
  description = "Initial prod task count."
  type        = number
  default     = 2
}

variable "ecs_min_capacity" {
  description = "Prod ECS autoscaling minimum."
  type        = number
  default     = 2
}

variable "ecs_max_capacity" {
  description = "Prod ECS autoscaling maximum."
  type        = number
  default     = 6
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
  description = "Prod CloudWatch log retention."
  type        = number
  default     = 30
}

variable "database_engine_version" {
  description = "RDS PostgreSQL major version."
  type        = string
  default     = "17"
}

variable "database_instance_class" {
  description = "Prod RDS instance class."
  type        = string
  default     = "db.t4g.small"
}

variable "database_allocated_storage" {
  description = "Initial prod RDS gp3 storage in GiB."
  type        = number
  default     = 20
}

variable "database_max_allocated_storage" {
  description = "Maximum prod RDS autoscaled storage in GiB."
  type        = number
  default     = 200
}

variable "database_multi_az" {
  description = "Enable Multi-AZ RDS in prod."
  type        = bool
  default     = true
}

variable "database_backup_retention_period" {
  description = "Prod automated backup retention in days."
  type        = number
  default     = 30
}

variable "database_deletion_protection" {
  description = "Enable RDS deletion protection in prod."
  type        = bool
  default     = true
}

variable "database_skip_final_snapshot" {
  description = "Skip final RDS snapshot in prod."
  type        = bool
  default     = false
}

variable "database_ssl_reject_unauthorized" {
  description = "Verify the RDS TLS certificate chain from NestJS."
  type        = bool
  default     = true
}

variable "secret_recovery_window_in_days" {
  description = "Prod secret deletion recovery window."
  type        = number
  default     = 30
}

variable "alb_deletion_protection" {
  description = "Enable ALB deletion protection in prod."
  type        = bool
  default     = true
}

variable "enable_github_deployment_role" {
  description = "Create a production GitHub Actions deployment role."
  type        = bool
  default     = false
}

variable "github_oidc_subject" {
  description = "Exact GitHub OIDC subject allowed to deploy production when enabled."
  type        = string
  default     = null
  nullable    = true
}
