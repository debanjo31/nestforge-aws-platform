resource "aws_cloudwatch_log_group" "ecs_api" {
  name              = "/ecs/${var.name_prefix}-api"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.name_prefix}-api-logs"
  }
}
