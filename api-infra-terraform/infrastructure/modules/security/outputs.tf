output "alb_security_group_id" {
  description = "Security group attached to the ALB."
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "Security group attached to ECS tasks."
  value       = aws_security_group.ecs.id
}

output "rds_security_group_id" {
  description = "Security group attached to RDS."
  value       = aws_security_group.rds.id
}
