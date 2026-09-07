resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = var.database_subnet_ids

  tags = {
    Name = "${var.name_prefix}-db-subnet-group"
  }
}

resource "aws_db_instance" "this" {
  identifier = "${var.name_prefix}-rds"

  engine                      = "postgres"
  engine_version              = var.engine_version
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false

  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.database_name
  username = var.database_username
  password = var.database_password
  port     = var.database_port

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  copy_tags_to_snapshot   = true

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name_prefix}-rds-final"
  delete_automated_backups  = false

  apply_immediately                   = false
  enabled_cloudwatch_logs_exports     = ["postgresql"]
  iam_database_authentication_enabled = false

  lifecycle {
    precondition {
      condition     = var.max_allocated_storage == 0 || var.max_allocated_storage >= var.allocated_storage
      error_message = "max_allocated_storage must be zero or at least allocated_storage."
    }
  }

  tags = {
    Name = "${var.name_prefix}-rds"
  }
}
