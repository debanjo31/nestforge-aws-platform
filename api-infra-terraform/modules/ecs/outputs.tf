output "cluster_name" {
  description = "Name of the ECS cluster."
  value       = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster."
  value       = aws_ecs_cluster.this.arn
}

output "service_name" {
  description = "Name of the ECS API service."
  value       = aws_ecs_service.api.name
}

output "task_definition_arn" {
  description = "ARN of the ECS API task definition revision."
  value       = aws_ecs_task_definition.api.arn
}

output "autoscaling_policy_arn" {
  description = "ARN of the ECS CPU target tracking policy."
  value       = aws_appautoscaling_policy.ecs_cpu.arn
}
