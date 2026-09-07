variable "name_prefix" {
  description = "Prefix applied to ALB resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC containing the load balancer and target group."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs used by the internet-facing ALB."
  type        = list(string)
}

variable "security_group_id" {
  description = "ALB security group ID."
  type        = string
}

variable "application_port" {
  description = "Port used by the NestJS targets."
  type        = number
  default     = 3000
}

variable "health_check_path" {
  description = "Path used for ALB target health checks."
  type        = string
  default     = "/health"
}

variable "enable_http_listener" {
  description = "Whether to create port 80. It forwards without a certificate and redirects when HTTPS is configured."
  type        = bool
  default     = true
}

variable "certificate_arn" {
  description = "Optional regional ACM certificate ARN. Null creates an HTTP-only test endpoint."
  type        = string
  default     = null
  nullable    = true
}

variable "ssl_policy" {
  description = "TLS security policy used by the HTTPS listener."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "deletion_protection" {
  description = "Whether ALB deletion protection is enabled."
  type        = bool
  default     = false
}
