output "ecs_execution_role_arn" {
  description = "ARN of the ECS task execution role."
  value       = aws_iam_role.ecs_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the application task role."
  value       = aws_iam_role.ecs_task.arn
}

output "ecs_execution_role_name" {
  description = "Name of the ECS task execution role."
  value       = aws_iam_role.ecs_execution.name
}

output "ecs_task_role_name" {
  description = "Name of the application task role."
  value       = aws_iam_role.ecs_task.name
}

output "github_deployment_role_arn" {
  description = "ARN of the GitHub Actions deployment role, or null when disabled."
  value       = try(aws_iam_role.github_deployment[0].arn, null)
}
