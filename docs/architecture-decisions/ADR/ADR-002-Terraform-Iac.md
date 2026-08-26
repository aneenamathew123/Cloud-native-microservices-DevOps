## Use Terraform with an Amazon S3 remote state backend and DynamoDB-based state locking.

The provisioning of AWS infrastructure includes VPC, subnets, NAT gateway, EKS cluster, node groups, IAM roles and policies
and an S3 bucket for terraform state storage and a DynamoDB table for state locking. When cost management matters, it is required
to destroy the infrastructure and for quick deployment and consistency across environments it is required to be reproducible.

The primary tools which are evaluated as Terraform, AWS CloudFormation, Pulumi, AWS CDK.

## Decision:

The project uses an S3 backend with DynamoDB-based state locking. Terraform now also supports S3-native locking through use_lockfile;
DynamoDB-based locking is retained in this project for compatibility with the implemented configuration. It is organised into three 
separate root modules:

terraform/
├── bootstrap/    # S3 bucket + DynamoDB lock table 
├── infra/        # VPC, EKS, ECR, IAM
└── platform/     # ArgoCD installation + root Application bootstrap.

## Rationale:

- Why Terraform over CloudFormation/AWS CDK/Pulumi.

Terraform differs fundamentally from CloudFormation, AWS CDK, in how it tracks changes, who manages the engine and how it
handles different cloud providers. CloudFormation is AWS-native and has deep-service integration. Both Terraform and CloudFormation 
provide mechanisms for previewing infrastructure changes. Terraform's plan workflow integrates directly with the Terraform configuration,
state, and provider ecosystem used by this project, making it a natural fit for the chosen multi-layer infrastructure workflow. When we type 
"terraform plan" command, it reads our code and check the cloud and generates a preview of the proposed infrastructure changes, including 
resources that Terraform intends to create, modify, or destroy, before those changes are applied. Terraform uses a declarative configuration 
language that keeps infrastructure definitions separate from application code while providing a consistent model for resources, modules,
variables, outputs, and providers.


- Why three seperate Terraform root modules

bootstrap/: Create S3 bucket and Dynamodb table for storing terraform state file, which infra and platform root modules can depend on. 

infra/: Create the infrastructure and network and exposes outputs (cluster_endpoint, cluster_ca, cluster_name) to its S3 state file.

platform/: It reads infra/ outputs via terraform_remote_state data source and uses them to configure the Helm and kubectl providers.

The benefit of seperating modules reduces the blast radius of dependency between components, for example platform level changes can be
planned and applied independently of underlying VPC and EKS infrastructure. However, dependencies between layers still exist and must be 
respected during provisioning and destruction.


## Tradeoffs:

| Consideration| Upside | Downside |
|---|---|---|
|Terraform | Multi-provider, declarative, strong plan workflow | Additional state management
| Separate root modules	| Isolated blast radius per layer | Multiple init/apply operations
| S3 Remote state | Centralized, durable shared state | S3 bucket must exist before 'terraform init' can run 
| State locking | prevent concurrent state operations | Additional backend configuration
| GitHub OIDC | No long-lived AWS credentials | IAM trust/policy configuration is more complex
| terraform_remote_state | Clean cross-module data sharing | Platform module silently fails if infra state is missing or keys differ
| Helm/Kubernetes providers | Platform can be managed through IaC | Requires reliable EKS authentication


## Challenges Encountered:

- Terraform Helm provider EKS auth failures: The helm provider failed to authenticate to EKS when run in CI because it was using a static 
                                             kubeconfig that did not exist. This caused authentication failures when Terraform to interact
                                             with the EKS API.

- Resolution: switched to the exec-based auth block using "aws eks get-token", which generates a short-lived token at plan/apply time


## Key Takeaways:

- Terraform state is the source of truth, Loss, corruption, or incorrect modification of Terraform state can prevent Terraform from
  accurately mapping configuration to existing infrastructure and may result in unsafe plans or resource recreation. Remote storage,
  versioning, access control, and state locking reduce these risks.

- Remote state storage can pass values between modules and eliminate providing values manually. The Terraform remote state data source depends on
  the correct backend configuration and incorrect bucket, key, region or workspace configuration can cause the platform layer to read the wrong state
  file or fail to retrieve expected outputs.

- GitHub Actions authenticates to AWS using GitHub OIDC rather than storing long-lived AWS access keys as repository secrets. 
  Seperate IAM roles are used for Terraform planning, infrastructure changes, and platform operations, following least-privilege principles.






