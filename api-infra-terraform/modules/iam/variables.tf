variable "name_prefix" {
  description = "Prefix applied to IAM role names."
  type        = string
}

variable "application_secret_arn" {
  description = "Secret ARN the ECS agent may inject into the task."
  type        = string
}

variable "aws_region" {
  description = "AWS region containing the ECS and ECR deployment targets."
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the ECR repository GitHub Actions may push to."
  type        = string
}

variable "enable_github_deployment_role" {
  description = "Whether to create the GitHub Actions application deployment role."
  type        = bool
  default     = false
}

variable "github_oidc_subject" {
  description = "Exact GitHub OIDC subject allowed to assume the deployment role."
  type        = string
  default     = null
  nullable    = true
}
