variable "name_prefix" {
  description = "Prefix applied to ECR resources."
  type        = string
}

variable "max_image_count" {
  description = "Maximum number of tagged images retained."
  type        = number
  default     = 30
}

variable "untagged_image_retention_days" {
  description = "Days to retain untagged images."
  type        = number
  default     = 7
}
