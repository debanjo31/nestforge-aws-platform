variable "project_name" {
  description = "Lowercase project identifier."
  type        = string
}

variable "environment" {
  description = "Environment identifier such as dev or prod."
  type        = string
}

variable "aws_region" {
  description = "AWS region for regional services and log configuration."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC IPv4 CIDR block."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Two public subnet CIDRs."
  type        = list(string)
}

variable "private_app_subnet_cidrs" {
  description = "Two private application subnet CIDRs."
  type        = list(string)
}

variable "private_db_subnet_cidrs" {
  description = "Two private database subnet CIDRs."
  type        = list(string)
}

variable "availability_zones" {
  description = "Optional explicit availability zone pair."
  type        = list(string)
  default     = []
}

variable "application_port" {
  description = "NestJS application port."
  type        = number
  default     = 3000
}

variable "database_port" {
  description = "PostgreSQL port."
  type        = number
  default     = 5432
}

variable "enable_http_listener" {
  description = "Whether to create an HTTP listener for testing or HTTPS redirect."
  type        = bool
  default     = true
}

variable "certificate_arn" {
  description = "Optional regional ACM certificate ARN."
  type        = string
  default     = null
  nullable    = true
}

variable "alb_deletion_protection" {
  description = "Whether ALB deletion protection is enabled."
  type        = bool
  default     = false
}

variable "image_tag" {
  description = "Immutable ECR image tag deployed by ECS."
  type        = string
  default     = "manual-bootstrap"

  validation {
    condition     = can(regex("^[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}$", var.image_tag))
    error_message = "image_tag must be a valid Docker tag containing no more than 128 characters."
  }
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
  description = "Initial ECS task count."
  type        = number
}

variable "ecs_min_capacity" {
  description = "ECS service autoscaling minimum."
  type        = number
}

variable "ecs_max_capacity" {
  description = "ECS service autoscaling maximum."
  type        = number
}

variable "ecs_cpu_target" {
  description = "CPU utilization target for ECS service autoscaling."
  type        = number
  default     = 65
}

variable "enable_container_insights" {
  description = "Whether ECS Container Insights is enabled."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days."
  type        = number
}

variable "database_name" {
  description = "Initial PostgreSQL database name."
  type        = string
  default     = "nestforge"
}

variable "database_username" {
  description = "Generated-secret PostgreSQL master username."
  type        = string
  default     = "nestforge_admin"
}

variable "database_engine_version" {
  description = "Supported PostgreSQL major version."
  type        = string
  default     = "17"
}

variable "database_instance_class" {
  description = "RDS instance class."
  type        = string
}

variable "database_allocated_storage" {
  description = "Initial RDS storage in GiB."
  type        = number
}

variable "database_max_allocated_storage" {
  description = "Maximum RDS autoscaled storage in GiB."
  type        = number
}

variable "database_multi_az" {
  description = "Whether RDS uses a synchronous standby in another AZ."
  type        = bool
}

variable "database_backup_retention_period" {
  description = "Automated RDS backup retention in days."
  type        = number
}

variable "database_deletion_protection" {
  description = "Whether RDS deletion protection is enabled."
  type        = bool
}

variable "database_skip_final_snapshot" {
  description = "Whether RDS skips a final snapshot on deletion."
  type        = bool
}

variable "database_ssl_reject_unauthorized" {
  description = "Whether the NestJS PostgreSQL client verifies the RDS certificate chain."
  type        = bool
  default     = true
}

variable "secret_recovery_window_in_days" {
  description = "Secrets Manager deletion recovery window."
  type        = number
}
