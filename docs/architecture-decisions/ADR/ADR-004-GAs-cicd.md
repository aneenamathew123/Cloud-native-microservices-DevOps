## GitHub Actions as the CI and Infrastructure Automation Tool and ArgoCD as the GitOps tool

A CI/CD pipeline needed to 
- Build docker images for microservices (GO, python, Java) after security scanning on every push by the developer.
- Push image to a container registry for instance ghcr.io
- Update the image tag in the kubernetes manifests to trigger ArgoCD sync
- Run terraform plan on pull requests and terraform apply on merge to main
- Authenticate to AWS without storing long-lived IAM credentials

The primary tools which are evaluated as Github Actions, Gitlab CI and Jenkins.

## Decision:

 Use Github actions with OIDC based authentication with AWS to eliminate long-lived credentials storage on Github secrets and
 a three-role IAM based split across workflow types. Github actions doesn't directly modify kubernetes resources using 'Kubectl'.
 After a successful image build and security scan, the workflow updates the image, ArgoCD detects the Git change and continously 
 reconciles the kubernetes deployment.

## Rationale:

- Why Github actions over Jenkins/Gitlab CI

- Jenkins is the traditional choice for self-hosted CI and requires a persistent server for running workflows. It requires project/team to 
  operate and manage Jenkins controllers and its agents as well as it introduces security considerations. The larger plugin ecosystem needs
  regular plugin management, patching, access control, credential management and runner infrastructure. In contrast, GitHub-hosted runners 
  provide ephemeral execution environments for workflows, removing the need for the project to maintain persistent CI servers. It provides
  native integration with repositories, pull requests, branches, artifacts, secrets, environments, and status checks without introducing 
  a separate CI platform.

- Github Actions is the native CI for a Github hosted repository. GitLab CI is also excellent but would require either mirroring the 
  repository to GitLab or managing a cross-platform integration.

- Why OIDC over IAM access keys

  The Open ID Connect(OIDC) authentication eliminates the static storage of long-lived credentials inside the Github secrets to 
  authenticate  with AWS. The long-lived IAM keys stored in Github secrets poses security threat if the repository accidently become 
  public. Additionally, the rotation of the key brings manual operational overhead. On the other hand, Github actions obtains a short-lived
  OIDC JWT from Github's OIDC identity provider. AWS STS validates the token against Github's OIDC provider and IAM trust policy, then issues
  a temporary credential for the permitted role session. No long-lived AWS access key is stored in GitHub Secrets.
   
  ## Tradeoffs:

| Consideration| Upside | Downside |
|---|---|---|
| Github Actions vs Jenkins | No need to maintain servers for workflows | Runners are ephemeral; artifacts/cache must be explicitly persisted
| OIDC vs IAM Keys | Short-lived tokens | Requires IAM OIDC provider and correct trust policy configuration
| GitOps deployment	| CI doesn't need direct kubernetes credentials	| Deployment depends on repo update and ArgoCD reconciliation
| Trivy scanning | Blocks known high-risk vulnerabilities | can block builds on vulnerabilities with no avialable fixes

## Security Considerations:

- Github actions uses OIDC rather than long-lived AWS access keys.
- IAM roles are separated by workflow purpose.
- Trust policies restrict which repository/branch can assume each role.
- CI does not receive Kubernetes administrator credentials.
- Container images are scanned before being published.
- GitOps changes are reviewed through Git rather than direct kubectl access.
- Secrets should not be printed into workflow logs.
- Github actions permissions should use least privilege (contents: read unless write is required).

 
 ## Challenges Encountered:

- Proto generation failures for Java ad-service: The Gradle build for the Java ad-service failed because the protobuf source directory 
                                                 was not found at the default location. 

- Resolution: passed the -PprotoSourceDir Gradle property explicitly in the CI build step to point at the correct path.

- Trivy security scanning blocking on OS-level CVEs: Trivy was configured to fail the build on any HIGH or CRITICAL CVE, including
                                                     CVEs in the base OS layer that had no available fix. 
                                                      
- Resolution: split the Trivy scan into two steps OS/library CVEs and application dependency CVEs. Accepted OS-level vulnerabilities with 
              no available fix were documented in .trivyignore with an explicit review/acceptance process, while application level dependency
              vulnerabilites remained blocking according to configured severity threshold.

## Key Takeaways:

- In this project the CI on every developer push code changes is handled by Github actions and deployment to the EKS cluster is 
  handled by ArgoCD. Github actions updates the Git file and never runs kubectl.

- Although OIDC requires additional initial IAM trust policy configuration, It eliminates the long-lived credential storage in Github secrets and 
  it significantly reduces credential rotation and compromises risk.

- Separating IAM roles by workflow type limits the impact of configuration errors. A pull request workflow using the plan role cannot modify the 
  infrastructure and that are only permitted to the apply role.
  





