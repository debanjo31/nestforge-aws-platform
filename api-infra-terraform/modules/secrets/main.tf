resource "random_password" "database" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}:?"
}

resource "random_password" "jwt" {
  length  = 64
  special = false
}

resource "aws_secretsmanager_secret" "application" {
  name                    = "${var.name_prefix}/api"
  description             = "Database credentials and JWT signing secret for NestForge"
  recovery_window_in_days = var.recovery_window_in_days

  tags = {
    Name = "${var.name_prefix}-api-secrets"
  }
}

resource "aws_secretsmanager_secret_version" "application" {
  secret_id = aws_secretsmanager_secret.application.id

  secret_string = jsonencode({
    DB_USERNAME = var.database_username
    DB_PASSWORD = random_password.database.result
    JWT_SECRET  = random_password.jwt.result
  })
}
