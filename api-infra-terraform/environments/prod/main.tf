module "platform" {
  source = "../../modules/platform"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  vpc_cidr                 = var.vpc_cidr
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
  availability_zones       = var.availability_zones

  image_tag                 = var.image_tag
  certificate_arn           = var.certificate_arn
  enable_http_listener      = var.enable_http_listener
  alb_deletion_protection   = var.alb_deletion_protection
  task_cpu                  = var.task_cpu
  task_memory               = var.task_memory
  ecs_desired_count         = var.ecs_desired_count
  ecs_min_capacity          = var.ecs_min_capacity
  ecs_max_capacity          = var.ecs_max_capacity
  ecs_cpu_target            = var.ecs_cpu_target
  enable_container_insights = var.enable_container_insights
  log_retention_days        = var.log_retention_days

  database_engine_version          = var.database_engine_version
  database_instance_class          = var.database_instance_class
  database_allocated_storage       = var.database_allocated_storage
  database_max_allocated_storage   = var.database_max_allocated_storage
  database_multi_az                = var.database_multi_az
  database_backup_retention_period = var.database_backup_retention_period
  database_deletion_protection     = var.database_deletion_protection
  database_skip_final_snapshot     = var.database_skip_final_snapshot
  database_ssl_reject_unauthorized = var.database_ssl_reject_unauthorized
  secret_recovery_window_in_days   = var.secret_recovery_window_in_days
}
