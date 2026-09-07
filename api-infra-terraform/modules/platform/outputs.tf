output "vpc_id" {
  description = "ID of the environment VPC."
  value       = module.networking.vpc_id
}

output "availability_zones" {
  description = "Availability zones used by the environment."
  value       = module.networking.availability_zones
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.networking.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "Private application subnet IDs."
  value       = module.networking.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "Private database subnet IDs."
  value       = module.networking.private_db_subnet_ids
}

output "ecr_repository_url" {
  description = "ECR repository URL used by ECS."
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = module.ecs.service_name
}

output "ecs_task_definition_arn" {
  description = "ECS task definition ARN."
  value       = module.ecs.task_definition_arn
}

output "alb_dns_name" {
  description = "Public ALB DNS name."
  value       = module.alb.load_balancer_dns_name
}

output "alb_zone_id" {
  description = "ALB hosted zone ID for future Route 53 aliases."
  value       = module.alb.load_balancer_zone_id
}

output "application_url" {
  description = "Application URL using the configured listener protocol."
  value       = "${var.certificate_arn == null ? "http" : "https"}://${module.alb.load_balancer_dns_name}"
}

output "rds_endpoint" {
  description = "RDS endpoint including port."
  value       = module.rds.database_endpoint
}

output "rds_port" {
  description = "RDS PostgreSQL port."
  value       = module.rds.database_port
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch Logs group used by ECS."
  value       = module.monitoring.log_group_name
}

output "application_secret_arn" {
  description = "Secrets Manager ARN injected into ECS. Secret values are never output."
  value       = module.secrets.secret_arn
}

output "security_group_ids" {
  description = "Security group IDs for the ALB, ECS tasks, and RDS."
  value = {
    alb = module.security.alb_security_group_id
    ecs = module.security.ecs_security_group_id
    rds = module.security.rds_security_group_id
  }
}

output "aws_region" {
  description = "AWS region containing the environment."
  value       = var.aws_region
}

output "ecs_task_definition_family" {
  description = "ECS task definition family used by application deployments."
  value       = module.ecs.task_definition_family
}

output "ecs_execution_role_arn" {
  description = "ARN of the ECS task execution role."
  value       = module.iam.ecs_execution_role_arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS application task role."
  value       = module.iam.ecs_task_role_arn
}

output "github_deployment_role_arn" {
  description = "ARN of the GitHub Actions deployment role, or null when disabled."
  value       = module.iam.github_deployment_role_arn
}
