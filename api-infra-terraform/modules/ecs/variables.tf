variable "name_prefix" {
  description = "Prefix applied to ECS resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "aws_region" {
  description = "AWS region used by the awslogs driver."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private application subnets used by ECS tasks."
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group attached to ECS task ENIs."
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group receiving ECS task registrations."
  type        = string
}

variable "container_image" {
  description = "Complete ECR image URI including an immutable tag."
  type        = string
}

variable "container_port" {
  description = "NestJS container port."
  type        = number
  default     = 3000
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

variable "desired_count" {
  description = "Initial number of running ECS tasks."
  type        = number
}

variable "minimum_healthy_percent" {
  description = "Minimum healthy percentage during rolling deployments."
  type        = number
  default     = 100
}

variable "maximum_percent" {
  description = "Maximum running percentage during rolling deployments."
  type        = number
  default     = 200
}

variable "health_check_grace_period_seconds" {
  description = "Time ECS ignores failing load balancer health checks after a task starts."
  type        = number
  default     = 60
}

variable "log_group_name" {
  description = "CloudWatch Logs group used by the container."
  type        = string
}

variable "application_secret_arn" {
  description = "Secrets Manager secret containing DB_USERNAME, DB_PASSWORD, and JWT_SECRET keys."
  type        = string
}

variable "execution_role_arn" {
  description = "ECS execution role ARN."
  type        = string
}

variable "task_role_arn" {
  description = "Application task role ARN."
  type        = string
}

variable "database_host" {
  description = "RDS hostname supplied to NestJS as DB_HOST."
  type        = string
}

variable "database_port" {
  description = "RDS PostgreSQL port supplied to NestJS."
  type        = number
  default     = 5432
}

variable "database_name" {
  description = "PostgreSQL database name supplied to NestJS."
  type        = string
}

variable "database_ssl_reject_unauthorized" {
  description = "Whether the PostgreSQL client verifies the RDS certificate chain."
  type        = bool
  default     = true
}

variable "jwt_expires_in" {
  description = "JWT expiration duration supplied to NestJS."
  type        = string
  default     = "1h"
}

variable "enable_container_insights" {
  description = "Whether ECS Container Insights is enabled."
  type        = bool
  default     = true
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of ECS tasks."
  type        = number
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of ECS tasks."
  type        = number
}

variable "autoscaling_cpu_target" {
  description = "Average ECS service CPU utilization target."
  type        = number
  default     = 65

  validation {
    condition     = var.autoscaling_cpu_target > 0 && var.autoscaling_cpu_target <= 100
    error_message = "autoscaling_cpu_target must be greater than 0 and at most 100."
  }
}
