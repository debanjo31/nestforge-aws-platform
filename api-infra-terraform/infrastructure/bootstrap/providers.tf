provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "NestForge"
      Environment = "shared"
      ManagedBy   = "Terraform"
      Application = "nestforge-api"
    }
  }
}
