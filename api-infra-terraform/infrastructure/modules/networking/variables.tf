variable "name_prefix" {
  description = "Prefix applied to networking resource names."
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "Two CIDR blocks for public subnets."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == 2 && alltrue([for cidr in var.public_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "public_subnet_cidrs must contain exactly two valid IPv4 CIDR blocks."
  }
}

variable "private_app_subnet_cidrs" {
  description = "Two CIDR blocks for private application subnets."
  type        = list(string)

  validation {
    condition     = length(var.private_app_subnet_cidrs) == 2 && alltrue([for cidr in var.private_app_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "private_app_subnet_cidrs must contain exactly two valid IPv4 CIDR blocks."
  }
}

variable "private_db_subnet_cidrs" {
  description = "Two CIDR blocks for private database subnets."
  type        = list(string)

  validation {
    condition     = length(var.private_db_subnet_cidrs) == 2 && alltrue([for cidr in var.private_db_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "private_db_subnet_cidrs must contain exactly two valid IPv4 CIDR blocks."
  }
}

variable "availability_zones" {
  description = "Optional explicit pair of availability zones. The first two available AZs are used when empty."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.availability_zones) == 0 || length(var.availability_zones) == 2
    error_message = "availability_zones must be empty or contain exactly two AZ names."
  }
}
