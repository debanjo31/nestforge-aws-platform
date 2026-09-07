variable "name_prefix" {
  description = "Prefix applied to Secrets Manager resources."
  type        = string
}

variable "database_username" {
  description = "PostgreSQL master username stored in Secrets Manager."
  type        = string
  default     = "nestforge_admin"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]+$", var.database_username))
    error_message = "database_username must start with a letter and contain only letters, numbers, and underscores."
  }
}

variable "recovery_window_in_days" {
  description = "Secrets Manager recovery window. Use 0 only for disposable development environments."
  type        = number
  default     = 7

  validation {
    condition     = var.recovery_window_in_days == 0 || (var.recovery_window_in_days >= 7 && var.recovery_window_in_days <= 30)
    error_message = "recovery_window_in_days must be 0 or between 7 and 30."
  }
}
