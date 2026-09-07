locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = {
    Project     = "NestForge"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Application = "nestforge-api"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
