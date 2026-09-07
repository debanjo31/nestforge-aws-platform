data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

locals {
  github_oidc_provider_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
  ecs_cluster_arn          = "arn:${data.aws_partition.current.partition}:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.name_prefix}-ecs-cluster"
  ecs_service_arn          = "arn:${data.aws_partition.current.partition}:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${var.name_prefix}-ecs-cluster/${var.name_prefix}-api-service"
  ecs_task_definition_arn  = "arn:${data.aws_partition.current.partition}:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:task-definition/${var.name_prefix}-api:*"
  ecs_task_arn             = "arn:${data.aws_partition.current.partition}:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:task/${var.name_prefix}-ecs-cluster/*"
}

resource "aws_iam_role" "ecs_execution" {
  name               = "${var.name_prefix}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json

  tags = {
    Name = "${var.name_prefix}-ecs-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_managed" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_execution_secrets" {
  statement {
    sid    = "ReadApplicationSecret"
    effect = "Allow"
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue"
    ]
    resources = [var.application_secret_arn]
  }
}

resource "aws_iam_role_policy" "ecs_execution_secrets" {
  name   = "${var.name_prefix}-read-application-secret"
  role   = aws_iam_role.ecs_execution.id
  policy = data.aws_iam_policy_document.ecs_execution_secrets.json
}

resource "aws_iam_role" "ecs_task" {
  name               = "${var.name_prefix}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json

  tags = {
    Name = "${var.name_prefix}-ecs-task-role"
  }
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  count = var.enable_github_deployment_role ? 1 : 0

  statement {
    sid     = "GitHubActionsMainBranch"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [var.github_oidc_subject]
    }
  }
}

resource "aws_iam_role" "github_deployment" {
  count = var.enable_github_deployment_role ? 1 : 0

  name                 = "${var.name_prefix}-github-deploy-role"
  assume_role_policy   = data.aws_iam_policy_document.github_actions_assume_role[0].json
  max_session_duration = 3600

  lifecycle {
    precondition {
      condition     = var.github_oidc_subject != null && can(regex("^repo:[^:]+:ref:refs/heads/[^:]+$", var.github_oidc_subject))
      error_message = "github_oidc_subject must be an exact repository branch subject when the deployment role is enabled."
    }
  }

  tags = {
    Name = "${var.name_prefix}-github-deploy-role"
  }
}

data "aws_iam_policy_document" "github_deployment" {
  count = var.enable_github_deployment_role ? 1 : 0

  statement {
    sid       = "GetECRAuthorizationToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PushApplicationImage"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = [var.ecr_repository_arn]
  }

  statement {
    sid       = "RegisterTaskDefinition"
    effect    = "Allow"
    actions   = ["ecs:RegisterTaskDefinition"]
    resources = ["*"]
  }

  statement {
    sid       = "ReadTaskDefinition"
    effect    = "Allow"
    actions   = ["ecs:DescribeTaskDefinition"]
    resources = [local.ecs_task_definition_arn]
  }

  statement {
    sid    = "DeployApplicationService"
    effect = "Allow"
    actions = [
      "ecs:DescribeServices",
      "ecs:UpdateService"
    ]
    resources = [local.ecs_service_arn]
  }

  statement {
    sid       = "RunMigrationTask"
    effect    = "Allow"
    actions   = ["ecs:RunTask"]
    resources = [local.ecs_task_definition_arn]

    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values   = [local.ecs_cluster_arn]
    }
  }

  statement {
    sid       = "ReadMigrationTask"
    effect    = "Allow"
    actions   = ["ecs:DescribeTasks"]
    resources = [local.ecs_task_arn]
  }

  statement {
    sid     = "PassECSTaskRoles"
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      aws_iam_role.ecs_execution.arn,
      aws_iam_role.ecs_task.arn
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "github_deployment" {
  count = var.enable_github_deployment_role ? 1 : 0

  name   = "${var.name_prefix}-github-deploy"
  role   = aws_iam_role.github_deployment[0].id
  policy = data.aws_iam_policy_document.github_deployment[0].json
}
