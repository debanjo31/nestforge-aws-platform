locals {
  container_name = "api"
}

resource "aws_ecs_cluster" "this" {
  name = "${var.name_prefix}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = {
    Name = "${var.name_prefix}-ecs-cluster"
  }
}

resource "aws_ecs_task_definition" "api" {
  family                   = "${var.name_prefix}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.task_cpu)
  memory                   = tostring(var.task_memory)
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = local.container_name
      image     = var.container_image
      essential = true

      portMappings = [
        {
          name          = "http"
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]

      environment = [
        { name = "NODE_ENV", value = "production" },
        { name = "PORT", value = tostring(var.container_port) },
        { name = "DB_HOST", value = var.database_host },
        { name = "DB_PORT", value = tostring(var.database_port) },
        { name = "DB_NAME", value = var.database_name },
        { name = "DB_SSL", value = "true" },
        { name = "DB_SSL_REJECT_UNAUTHORIZED", value = tostring(var.database_ssl_reject_unauthorized) },
        { name = "JWT_EXPIRES_IN", value = var.jwt_expires_in }
      ]

      secrets = [
        { name = "DB_USERNAME", valueFrom = "${var.application_secret_arn}:DB_USERNAME::" },
        { name = "DB_PASSWORD", valueFrom = "${var.application_secret_arn}:DB_PASSWORD::" },
        { name = "JWT_SECRET", valueFrom = "${var.application_secret_arn}:JWT_SECRET::" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
          mode                    = "non-blocking"
          "max-buffer-size"       = "25m"
        }
      }

      healthCheck = {
        command = [
          "CMD-SHELL",
          "node -e \"fetch('http://127.0.0.1:${var.container_port}/health').then(r=>{if(!r.ok)process.exit(1)}).catch(()=>process.exit(1))\""
        ]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }

      linuxParameters = {
        initProcessEnabled = true
      }

      readonlyRootFilesystem = true
      stopTimeout            = 30
    }
  ])

  tags = {
    Name = "${var.name_prefix}-api-task"
  }
}

resource "aws_ecs_service" "api" {
  name             = "${var.name_prefix}-api-service"
  cluster          = aws_ecs_cluster.this.id
  task_definition  = aws_ecs_task_definition.api.arn
  desired_count    = var.desired_count
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"

  deployment_minimum_healthy_percent = var.minimum_healthy_percent
  deployment_maximum_percent         = var.maximum_percent
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = local.container_name
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [
      desired_count,
      task_definition
    ]
  }

  tags = {
    Name = "${var.name_prefix}-api-service"
  }
}

resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  lifecycle {
    precondition {
      condition = (
        var.autoscaling_min_capacity <= var.desired_count &&
        var.desired_count <= var.autoscaling_max_capacity
      )
      error_message = "desired_count must be between autoscaling_min_capacity and autoscaling_max_capacity."
    }
  }
}

resource "aws_appautoscaling_policy" "ecs_cpu" {
  name               = "${var.name_prefix}-ecs-cpu-target"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = var.autoscaling_cpu_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
