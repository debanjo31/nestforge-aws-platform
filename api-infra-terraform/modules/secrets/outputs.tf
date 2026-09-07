output "secret_arn" {
  description = "ARN of the application secret used by the ECS execution role."
  value       = aws_secretsmanager_secret.application.arn
}

output "database_username" {
  description = "Database username stored in the application secret."
  value       = var.database_username
}

output "database_password" {
  description = "Generated database password. This is passed directly to RDS and is not exposed by environment roots."
  value       = random_password.database.result
  sensitive   = true
}
