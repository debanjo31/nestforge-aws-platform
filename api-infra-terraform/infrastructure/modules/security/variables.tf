variable "name_prefix" {
  description = "Prefix applied to security group names."
  type        = string
}

variable "vpc_id" {
  description = "VPC in which to create the security groups."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR used to scope DNS egress."
  type        = string
}

variable "application_port" {
  description = "NestJS container port."
  type        = number
  default     = 3000
}

variable "database_port" {
  description = "PostgreSQL port."
  type        = number
  default     = 5432
}

variable "enable_http" {
  description = "Whether the ALB accepts port 80 for forwarding or HTTPS redirection."
  type        = bool
  default     = true
}

variable "enable_https" {
  description = "Whether the ALB accepts HTTPS on port 443."
  type        = bool
  default     = false
}
