output "log_group_name" {
  description = "CloudWatch log group used by the NestForge container."
  value       = aws_cloudwatch_log_group.ecs_api.name
}

output "log_group_arn" {
  description = "ARN of the NestForge CloudWatch log group."
  value       = aws_cloudwatch_log_group.ecs_api.arn
}
