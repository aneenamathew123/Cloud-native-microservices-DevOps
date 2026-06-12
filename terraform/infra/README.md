## Production-grade Kubernetes infrastructure on AWS using Terraform, EKS, GitHub Actions, and ArgoCD.
The architecture includes:

- Infrastructure as Code (IaC) based EKS cluster provisioning
- Custom VPC creation with public and private subnets
- Terraform remote backend using S3 and DynamoDB state locking
- GitHub Actions CI/CD with AWS OIDC authentication
- ArgoCD-based GitOps deployment
- OpenTelemetry microservices deployment on Kubernetes

## Repository Structure

```text
terraform/
├── bootstrap/     # Backend + IAM + OIDC setup
├── infra/         # VPC, EKS, node groups
├── platform/      # ArgoCD, platform services
apps/              # Kubernetes applications
.github/workflows/ # CI/CD pipelines
```

## Tools & Technologies
- Terraform
- AWS EKS
- Docker
- Kubernetes
- Helm
- ArgoCD
- GitHub Actions
- OpenTelemetry

## Deployment Flow

```text
Developer Push/PR
    ↓
GitHub Actions
    ↓
Terraform Infrastructure
    ↓
EKS Cluster
    ↓
ArgoCD Installation
    ↓
Application GitOps Sync
```