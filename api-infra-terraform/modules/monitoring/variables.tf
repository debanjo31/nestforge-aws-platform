variable "name_prefix" {
  description = "Prefix applied to monitoring resources."
  type        = string
}

variable "log_retention_days" {
  description = "Number of days ECS application logs are retained."
  type        = number
  default     = 14
}
