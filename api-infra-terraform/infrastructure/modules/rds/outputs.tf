output "database_instance_id" {
  description = "RDS instance identifier."
  value       = aws_db_instance.this.id
}

output "database_address" {
  description = "RDS hostname without the port."
  value       = aws_db_instance.this.address
}

output "database_endpoint" {
  description = "RDS endpoint including the port."
  value       = aws_db_instance.this.endpoint
}

output "database_port" {
  description = "RDS PostgreSQL port."
  value       = aws_db_instance.this.port
}

output "database_subnet_group_name" {
  description = "RDS DB subnet group name."
  value       = aws_db_subnet_group.this.name
}
