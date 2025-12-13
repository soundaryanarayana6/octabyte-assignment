# Octabyte Assignment Project

This repo contains my submission for the Octabyte DevOps assignment.

The goal was to keep the stack simple but realistic: Terraform for infrastructure, ECS (Fargate) for compute, an ALB for ingress, RDS (PostgreSQL) for persistence, and GitHub Actions for CI/CD. CloudWatch is used for logs and dashboards.

## Repository layout

- `terraform/` — infrastructure (VPC, ALB, ECS, RDS, ECR, CloudWatch)
- `backend/` — backend service
- `.github/workflows/` — CI and CD pipelines

## How to set up and run the infrastructure

### Prerequisites

- AWS CLI installed and configured (`aws configure`)
- Terraform v1.14.1
- An AWS account with necessary permissions to create required resources

### Terraform inputs

Terraform uses the variables defined in `terraform/variables.tf`. The only required input is:

- `db_password` (sensitive)

Commonly used variables:

- `environment` (default: `staging`)
- `aws_region` (default: `us-east-1`)

### Deploy from your machine

From the repo root:

```bash
cd terraform

terraform init -backend-config="key=staging/terraform.tfstate"
terraform plan -var="environment=staging" -var="db_password=YOUR_SECURE_PASSWORD"
terraform apply -var="environment=staging" -var="db_password=YOUR_SECURE_PASSWORD"
```

To deploy prod, use the prod state key and environment:

```bash
cd terraform

terraform init -backend-config="key=prod/terraform.tfstate"
terraform apply -var="environment=prod" -var="db_password=YOUR_SECURE_PASSWORD"
```

### Tear down

```bash
cd terraform
terraform destroy -var="environment=staging" -var="db_password=YOUR_SECURE_PASSWORD"
```

## CI/CD

Workflows live in `.github/workflows/`:

- `ci.yaml`
  - runs on PRs to `main`
  - runs Go unit tests
  - runs Trivy repo scan

- `deploy.yaml`
  - runs on pushes to `main`
  - applies Terraform
  - builds a Docker image and pushes it to ECR
  - forces a new ECS deployment

### GitHub Secrets

Required:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `DB_PASSWORD`

Email notifications on workflow failures:

- `SMTP_SERVER`
- `SMTP_PORT`
- `SMTP_USERNAME`
- `SMTP_PASSWORD`
- `EMAIL_FROM`
- `EMAIL_TO`

Gmail example:

- `SMTP_SERVER`: `smtp.gmail.com`
- `SMTP_PORT`: `587`
- `SMTP_USERNAME`: `yourname@gmail.com`
- `SMTP_PASSWORD`: Google App Password (not your normal password)

## Architecture decisions (and why)

### Infrastructure strategy

- **Cloud provider**: AWS
- **Compute**: ECS on Fargate
  - I picked Fargate to avoid managing EC2 instances/ASGs for the cluster.
  - It also avoids EKS control-plane costs, which didn’t make sense for this scope.

### Networking

- VPC with public and private subnets across two AZs
- ALB is public-facing and receives HTTP traffic
- The ECS service is registered behind the ALB target group

Trade-off (kept intentionally simple for the assignment):

- ECS tasks are running in **public subnets** with `assign_public_ip = true`. In a production setup, I’d normally move tasks to private subnets and control outbound traffic more strictly.

### Database

- RDS PostgreSQL is deployed into private subnets
- Public access is disabled (`publicly_accessible = false`)

## Monitoring and logging

- CloudWatch log groups for application logs
- CloudWatch dashboards for a quick view of infra and ALB metrics
- ALB access logs enabled and delivered to S3

## Security considerations

### Network boundaries

- DB is private (not publicly accessible)
- Security groups should restrict:
  - ALB inbound from the internet (HTTP)
  - app inbound only from the ALB
  - DB inbound only from the app

### Secrets

- `db_password` is a Terraform sensitive variable and is passed via GitHub Secrets in CI/CD.
- For a production version, I’d move DB credentials into AWS Secrets Manager and inject them at runtime.

### Supply chain

- Trivy scanning is used to catch obvious critical/high issues early.

## Cost optimization measures

The cost controls here are mostly “keep the footprint small” choices:

- Small Fargate task size (low CPU/memory)
- `db.t3.micro` for RDS for a low-cost database baseline
- 7-day CloudWatch log retention to avoid unbounded log spend
- ECS service `desired_count = 1` by default

## Challenges and resolutions

These are the main issues I ran into and how they were handled:

1. **Handling secrets in Terraform**
   - DB password is marked as sensitive and passed at apply time. It’s never committed to git.

2. **Cost vs availability**
   - A NAT Gateway per AZ is expensive for a small assessment environment.
   - For this project, tasks run publicly (no NAT) to keep the bill down, with the trade-off called out above.

3. **ALB access logs → S3 permissions**
   - ALB logging initially failed with S3 “Access Denied”.
   - Fixed by tightening the bucket policy to allow ELB log delivery and adding the required write permissions.

4. **CloudWatch dashboard validation**
   - The dashboard body failed validation (“Should NOT have more than 4 items”).
   - Fixed by rewriting widgets/metric rows to match CloudWatch’s expected schema.

5. **Dependency ordering in Terraform**
   - Security group and listener dependencies were handled using resource references (and explicit dependencies where needed) so the graph applies cleanly.

## What we actually changed while debugging

This is the short version of what happened:

- fixed the ALB → S3 access log bucket policy
- fixed CloudWatch dashboard schema issues in `terraform/monitoring.tf`
- added email notifications for GitHub Actions failures (SMTP)
- consolidated documentation into this README
