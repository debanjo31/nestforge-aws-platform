# NestForge Infrastructure

## Overview

This directory provisions the AWS platform for the NestForge NestJS API:

- a two-AZ, three-tier VPC;
- a public Application Load Balancer;
- private ECS Fargate tasks;
- private Amazon RDS for PostgreSQL;
- ECR, Secrets Manager, IAM, CloudWatch Logs, and ECS Service Auto Scaling;
- an isolated S3 backend bootstrap with versioning, encryption, TLS enforcement, public-access blocking, and native S3 lockfiles.

Terraform does not build or push the application image. The ECR repository must contain the configured immutable `image_tag` before the full ECS service is created.

## Prerequisites

- Terraform `>= 1.10.0, < 2.0.0`
- AWS CLI v2
- Docker for the initial manual image push
- An AWS account and an authenticated AWS credential-provider-chain session
- Permissions for the resources in this stack
- The NestForge API source and Dockerfile when building an image

Do not place AWS access keys in Terraform. Local authentication may come from an AWS CLI profile, environment credentials, IAM Identity Center, or an assumed role. GitHub OIDC is intentionally deferred.

Always verify the target before planning or applying:

```powershell
aws sts get-caller-identity
aws configure get region
```

Confirm the account ID, ARN, and intended region.

## Directory Structure

```text
infrastructure/
|-- bootstrap/                 # Local-state S3 backend bootstrap
|-- environments/
|   |-- dev/                   # Dev root and dev state key
|   `-- prod/                  # Prod root and prod state key
`-- modules/
    |-- networking/            # VPC, subnets, IGW, NAT, routes
    |-- security/              # ALB, ECS, and RDS security groups
    |-- ecr/                   # Repository, scanning, lifecycle policy
    |-- secrets/               # Generated DB/JWT values and secret version
    |-- iam/                   # ECS execution role and empty task role
    |-- rds/                   # DB subnet group and PostgreSQL instance
    |-- alb/                   # ALB, target group, HTTP/HTTPS listeners
    |-- monitoring/            # ECS CloudWatch log group
    |-- ecs/                   # Cluster, task, service, and CPU scaling
    `-- platform/              # Resource-free composition/wiring module
```

The `platform` composition module prevents dev/prod from duplicating resource wiring. Environment roots provide values and backend/state boundaries.

## Bootstrap Remote State

The bootstrap root intentionally uses local state because an S3 backend cannot use a bucket before that bucket exists. It creates only six remote-state resources: the bucket, ownership controls, public-access block, versioning, encryption configuration, and TLS-enforcing bucket policy.

The default bucket name is deterministic and globally differentiated by account ID:

```text
nestforge-terraform-state-<aws-account-id>
```

Use `terraform_state_bucket_name` only when an explicit globally unique override is required.

Run from the `api-infra-terraform` repository root:

```powershell
Copy-Item infrastructure/bootstrap/terraform.tfvars.example infrastructure/bootstrap/terraform.tfvars

aws sts get-caller-identity
terraform -chdir=infrastructure/bootstrap init
terraform -chdir=infrastructure/bootstrap fmt -check
terraform -chdir=infrastructure/bootstrap validate
terraform -chdir=infrastructure/bootstrap plan -out=bootstrap.tfplan
```

Review the plan. Applying is always an explicit manual step:

```powershell
terraform -chdir=infrastructure/bootstrap apply bootstrap.tfplan
terraform -chdir=infrastructure/bootstrap output terraform_state_bucket_name
```

The state bucket uses `prevent_destroy = true`. To intentionally remove it, first back up all state object versions, remove or temporarily disable the lifecycle guard in reviewed code, empty every object version and delete marker, and then perform a separately approved destroy. Losing bootstrap local state requires importing the existing bucket resources; do not create a replacement casually.

## Initialize Dev

After bootstrap has been applied, run from the `api-infra-terraform` repository root:

```powershell
Copy-Item infrastructure/environments/dev/terraform.tfvars.example infrastructure/environments/dev/terraform.tfvars

$stateBucket = terraform -chdir=infrastructure/bootstrap output -raw terraform_state_bucket_name
terraform -chdir=infrastructure/environments/dev init -reconfigure `
  -backend-config="bucket=$stateBucket" `
  -backend-config="key=nestforge/dev/terraform.tfstate" `
  -backend-config="region=us-east-1"

terraform -chdir=infrastructure/environments/dev fmt -check
terraform -chdir=infrastructure/environments/dev validate
terraform -chdir=infrastructure/environments/dev plan
```

The backend region must match the state bucket's region. The application `aws_region` may target a different region if that is an intentional design choice.

## Initialize Prod

After bootstrap has been applied, run from the `api-infra-terraform` repository root:

```powershell
Copy-Item infrastructure/environments/prod/terraform.tfvars.example infrastructure/environments/prod/terraform.tfvars

$stateBucket = terraform -chdir=infrastructure/bootstrap output -raw terraform_state_bucket_name
terraform -chdir=infrastructure/environments/prod init -reconfigure `
  -backend-config="bucket=$stateBucket" `
  -backend-config="key=nestforge/prod/terraform.tfstate" `
  -backend-config="region=us-east-1"

terraform -chdir=infrastructure/environments/prod fmt -check
terraform -chdir=infrastructure/environments/prod validate
terraform -chdir=infrastructure/environments/prod plan
```

Dev and prod deliberately use different root directories and state keys. Terraform workspaces are not the environment boundary.

## First Application Image

The repository is immutable and initially empty. A full first apply cannot stabilize ECS until the configured image exists. Use this reviewed two-stage bootstrap once per environment:

1. Initialize the environment backend.
2. Create only ECR after reviewing the targeted plan.
3. Build and push the exact configured tag.
4. Run a normal full plan and apply.

Example from `infrastructure/environments/dev`:

```powershell
terraform plan -target=module.platform.module.ecr
terraform apply -target=module.platform.module.ecr

$awsRegion = "us-east-1"
$imageTag = "manual-bootstrap"
$accountId = aws sts get-caller-identity --query Account --output text
$repositoryUrl = terraform output -raw ecr_repository_url
$registry = "$accountId.dkr.ecr.$awsRegion.amazonaws.com"
$apiPath = Resolve-Path ../../../../nestforge-api

aws ecr get-login-password --region $awsRegion | docker login --username AWS --password-stdin $registry
docker build --tag "${repositoryUrl}:${imageTag}" $apiPath
docker push "${repositoryUrl}:${imageTag}"

terraform plan
```

The subsequent full `terraform apply` remains manual. Targeting is used only to break the first-image dependency; routine changes must use normal full plans. Later CI/CD should build a tag such as `sha-a84bc23`, push it, and pass that tag as `image_tag`.

## HTTP and HTTPS

With `certificate_arn = null`, port 80 forwards to ECS for temporary testing. Supplying a validated ACM certificate ARN in the same AWS region creates an HTTPS listener on 443 and changes port 80 to a `301` redirect. Set `enable_http_listener = false` to expose HTTPS only.

Production should not remain HTTP-only. Route 53 and ACM certificate creation are not included; the ALB DNS name and hosted zone ID are output for future DNS integration.

## Database Migrations

Do not run TypeORM migrations in every API task startup. Concurrent task starts can race.

The intended process is a one-off ECS task using the same task definition and private network configuration, with the container command overridden to:

```text
node ./node_modules/typeorm/cli.js -d dist/database/data-source.js migration:run
```

Run it before an ECS service rollout, wait for a successful exit code, and only then update the service. Today this is a documented manual operation; a later GitHub Actions/OIDC deployment phase should automate it. No SSH or bastion is required.

## State Strategy and Locking

- State is stored in S3 with versioning and SSE-S3 (`AES256`).
- Native S3 lockfiles are enabled with `use_lockfile = true`.
- DynamoDB locking is not created because the S3 backend supports native locking and DynamoDB locking is deprecated.
- Backend blocks are partial because Terraform variables cannot be interpolated there.
- Credentials are never passed through backend arguments.
- The bootstrap state remains local and must be securely backed up.
- State can contain generated database and JWT values. Restrict backend access even though no secret values are root outputs.

The IAM principal running Terraform needs state-object access plus `GetObject`, `PutObject`, and `DeleteObject` on each `.tflock` object.

## Naming and Tags

Resources follow `nestforge-<environment>-<resource>`, for example:

- `nestforge-dev-vpc`
- `nestforge-dev-alb`
- `nestforge-dev-ecs-cluster`
- `nestforge-dev-api-service`
- `nestforge-dev-rds`

Provider default tags apply:

```text
Project     = NestForge
Environment = dev | prod
ManagedBy   = Terraform
Application = nestforge-api
```

## Variables

The supplied examples contain no secrets. Principal controls include:

- region, VPC/subnet CIDRs, and optional fixed AZ names;
- immutable image tag and optional ACM certificate ARN;
- Fargate CPU, memory, desired/min/max counts, and CPU target;
- PostgreSQL engine major, instance class, storage, Multi-AZ, backups, deletion protection, and final-snapshot behavior;
- log retention, Container Insights, and secret recovery window.

Generated DB and JWT values are stored in Secrets Manager. They also exist in Terraform state because Terraform generated them, which is why backend access is sensitive.

## Useful Commands

Static checks without initializing the remote backend:

```powershell
terraform fmt -recursive -check
terraform -chdir=infrastructure/bootstrap init -backend=false
terraform -chdir=infrastructure/bootstrap validate
terraform -chdir=infrastructure/environments/dev init -backend=false
terraform -chdir=infrastructure/environments/dev validate
terraform -chdir=infrastructure/environments/prod init -backend=false
terraform -chdir=infrastructure/environments/prod validate
```

Inspect outputs after apply:

```powershell
terraform output
terraform output -raw application_url
terraform output -raw ecr_repository_url
```

## Files and Source Control

Commit:

- all `.tf` files;
- all documentation;
- `terraform.tfvars.example` files;
- each root module's `.terraform.lock.hcl`.

Do not commit:

- `.terraform/`;
- `terraform.tfstate` or backups;
- real `terraform.tfvars`;
- saved `*.tfplan` files;
- credentials, secret values, or private backend configuration.

## Security Considerations

- RDS has no public address and its subnets have no default internet route.
- ECS has no public IP and accepts port 3000 only from the ALB security group.
- RDS accepts port 5432 only from the ECS security group.
- ALB egress is limited to the ECS application port.
- ECS egress is limited to RDS, HTTPS, and VPC DNS.
- The ECS execution role can pull images, publish logs, and read one application secret.
- The ECS task role has no permissions until the application needs a specific AWS API.
- Production enables ALB and RDS deletion protection, a final DB snapshot, Multi-AZ RDS, longer backups, and a 30-day secret recovery window.
- `DB_SSL_REJECT_UNAUTHORIZED` defaults to true. The application image must trust the current Amazon RDS CA bundle before deployment.

## Cost Considerations

The persistent cost drivers are the NAT Gateway, ALB, Fargate tasks, RDS, CloudWatch ingestion/retention, Secrets Manager, and data transfer. The single NAT Gateway is intentionally cost-conscious but creates an app-tier egress dependency on one AZ. Production can evolve to one NAT per AZ when resilience justifies the additional fixed cost.

Dev uses one task, a small Single-AZ RDS instance, 14-day logs, and short-lived secrets. Destroy disposable dev infrastructure when it is not needed, but preserve and protect remote state.

## Troubleshooting

- **Backend initialization required:** apply bootstrap, then rerun `terraform init -reconfigure` with all three backend arguments.
- **AccessDenied on `.tflock`:** grant `s3:GetObject`, `s3:PutObject`, and `s3:DeleteObject` on the state key's `.tflock` object.
- **ECS cannot stabilize:** confirm the exact `image_tag` exists, tasks have NAT egress, and inspect `/ecs/nestforge-<environment>-api` logs.
- **Targets stay unhealthy:** verify `/health` returns HTTP 200 and that the database connection is healthy.
- **PostgreSQL TLS fails:** install/trust the current Amazon RDS CA bundle in the application image; do not disable certificate verification in production.
- **Secret name is pending deletion:** restore it during the recovery window or use a different environment name. Dev uses immediate secret deletion by default.
- **Prod destroy fails:** deletion protection and final-snapshot safeguards are intentional. Change them only through a reviewed plan.
