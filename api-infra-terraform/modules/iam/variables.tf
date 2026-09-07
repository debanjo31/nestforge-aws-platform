variable "name_prefix" {
  description = "Prefix applied to IAM role names."
  type        = string
}

variable "application_secret_arn" {
  description = "Secret ARN the ECS agent may inject into the task."
  type        = string
}
