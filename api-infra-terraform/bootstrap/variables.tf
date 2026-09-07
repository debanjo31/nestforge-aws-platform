variable "aws_region" {
  description = "AWS region in which to create the Terraform state bucket."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Lowercase project identifier used in resource names."
  type        = string
  default     = "nestforge"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}[a-z0-9]$", var.project_name))
    error_message = "project_name must be a lowercase, DNS-safe name between 3 and 22 characters."
  }
}

variable "terraform_state_bucket_name" {
  description = "Optional globally unique state bucket name. When null, the AWS account ID is appended to the project name."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.terraform_state_bucket_name == null || can(regex(
      "^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$",
      var.terraform_state_bucket_name
    ))
    error_message = "terraform_state_bucket_name must be null or a valid 3-63 character S3 bucket name."
  }
}
