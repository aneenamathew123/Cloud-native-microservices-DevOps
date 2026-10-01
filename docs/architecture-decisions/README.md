## Architecture Decision Records

This folder documents the architecture decisions made throughout the Cloud-Native Microservices DevOps portfolio project. 
It explains the alternatives considered, the rationale behind each decision, the challenges encountered, the solutions implemented, 
the trade-offs involved, and the key lessons learned.

## Index:

| ADR | Decision |
|---|---|
| ADR-001 | Use Amazon EKS as the Kubernetes deployment environment. |
| ADR-002 | Use Terraform for AWS infrastructure provisioning. |
| ADR-003 | Use Argo CD for GitOps-based continuous delivery with the App of Apps pattern. |
| ADR-004 | Use GitHub Actions with OIDC for CI/CD automation. |


## Architecture Overview:
The Overall architecture diagram includes both infrastructure provisioning and Gitops-based application delivery.


```mermaid
flowchart LR

    DEV["Developer"]

    REPO["GitHub<br/>Application Repository"]

    CI["GitHub Actions<br/>CI"]

    GHCR["GHCR.io<br/>Container Registry"]

    GITOPS["GitOps Repository<br/>Kubernetes Manifests"]

    ARGO["Argo CD"]

    APP["App of Apps"]

    EKS["Amazon EKS"]

    ADS["ad-service"]
    REC["recommendation-service"]
    PRODUCT["product-catalog-service"]

    DEV --> REPO
    REPO --> CI
    CI -->|"Build & Push Image"| GHCR
    CI -->|"Update Image Tag"| GITOPS
    GITOPS -->|"Desired State"| ARGO
    ARGO --> APP
    APP --> ADS
    APP --> REC
    APP --> PRODUCT

    ADS --> EKS
    REC --> EKS
    PRODUCT --> EKS