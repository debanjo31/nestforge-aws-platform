locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

module "networking" {
  source = "../networking"

  name_prefix              = local.name_prefix
  vpc_cidr                 = var.vpc_cidr
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
  availability_zones       = var.availability_zones
}

module "security" {
  source = "../security"

  name_prefix      = local.name_prefix
  vpc_id           = module.networking.vpc_id
  vpc_cidr         = module.networking.vpc_cidr
  application_port = var.application_port
  database_port    = var.database_port
  enable_http      = var.enable_http_listener
  enable_https     = var.certificate_arn != null
}

module "ecr" {
  source = "../ecr"

  name_prefix = local.name_prefix
}

module "secrets" {
  source = "../secrets"

  name_prefix             = local.name_prefix
  database_username       = var.database_username
  recovery_window_in_days = var.secret_recovery_window_in_days
}

module "iam" {
  source = "../iam"

  name_prefix                   = local.name_prefix
  application_secret_arn        = module.secrets.secret_arn
  aws_region                    = var.aws_region
  ecr_repository_arn            = module.ecr.repository_arn
  enable_github_deployment_role = var.enable_github_deployment_role
  github_oidc_subject           = var.github_oidc_subject
}

module "monitoring" {
  source = "../monitoring"

  name_prefix        = local.name_prefix
  log_retention_days = var.log_retention_days
}

module "rds" {
  source = "../rds"

  name_prefix             = local.name_prefix
  database_subnet_ids     = module.networking.private_db_subnet_ids
  security_group_id       = module.security.rds_security_group_id
  database_name           = var.database_name
  database_username       = module.secrets.database_username
  database_password       = module.secrets.database_password
  database_port           = var.database_port
  engine_version          = var.database_engine_version
  instance_class          = var.database_instance_class
  allocated_storage       = var.database_allocated_storage
  max_allocated_storage   = var.database_max_allocated_storage
  multi_az                = var.database_multi_az
  backup_retention_period = var.database_backup_retention_period
  deletion_protection     = var.database_deletion_protection
  skip_final_snapshot     = var.database_skip_final_snapshot
}

module "alb" {
  source = "../alb"

  name_prefix          = local.name_prefix
  vpc_id               = module.networking.vpc_id
  public_subnet_ids    = module.networking.public_subnet_ids
  security_group_id    = module.security.alb_security_group_id
  application_port     = var.application_port
  enable_http_listener = var.enable_http_listener
  certificate_arn      = var.certificate_arn
  deletion_protection  = var.alb_deletion_protection
}

module "ecs" {
  source = "../ecs"

  name_prefix        = local.name_prefix
  environment        = var.environment
  aws_region         = var.aws_region
  private_subnet_ids = module.networking.private_app_subnet_ids
  security_group_id  = module.security.ecs_security_group_id
  target_group_arn   = module.alb.target_group_arn

  container_image = "${module.ecr.repository_url}:${var.image_tag}"
  container_port  = var.application_port
  task_cpu        = var.task_cpu
  task_memory     = var.task_memory
  desired_count   = var.ecs_desired_count

  log_group_name         = module.monitoring.log_group_name
  application_secret_arn = module.secrets.secret_arn
  execution_role_arn     = module.iam.ecs_execution_role_arn
  task_role_arn          = module.iam.ecs_task_role_arn

  database_host                    = module.rds.database_address
  database_port                    = module.rds.database_port
  database_name                    = var.database_name
  database_ssl_reject_unauthorized = var.database_ssl_reject_unauthorized

  enable_container_insights = var.enable_container_insights
  autoscaling_min_capacity  = var.ecs_min_capacity
  autoscaling_max_capacity  = var.ecs_max_capacity
  autoscaling_cpu_target    = var.ecs_cpu_target

  depends_on = [
    module.alb,
    module.iam,
    module.monitoring,
    module.secrets
  ]
}
