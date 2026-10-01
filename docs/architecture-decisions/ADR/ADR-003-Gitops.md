## GitOps Deployment Principle with ArgoCD and App of Apps Pattern

After provisioning the EKS cluster, a deployment strategy is needed for three microservices(ad-service, product-catalog, 
recommendation-service) and the platform add-ons (ingress-nginx, otel-collector). 
The core question is, who is authoritative for what runs in the cluster? For that, two models were evaluated as push-based deployment
and pull-based GitOps deployment.

- Push-based deployment model:
  In a push-based deployment, the CI/CD pipeline authenticates to the target cluster and apply changes directly, for example 
  using kubectl or Helm. Although the model supports audit logs, and rollback mechanisms, it doesn't inherently provide 
  continuous reconciliation between the desired state in Git and the live state of the cluster.

- Pull-based deployment model:
  In a pull-based deployment, the resources managed by ArgoCD depends on Git as the single source of truth for the desired state.
  Argo CD continuously compares the desired state defined in Git with the live state in Kubernetes and reconciles detected differences 
  according to the application's sync policy.



## Decision:

Adopted GitOps as the deployment principle using ArgoCD as the GitOps controller, structured with the App of Apps pattern.

## Rationale:

The push based deployment using kubectl apply actually works but it has some fundamental weaknesses over pull based deployment.

- No continuous drift detection: If someone manually modifies a kubernetes resource using kubectl, the live cluster state can diverge
                                from the last configuration deployed by the CI pipeline. It has no continuous reconciliation process that
                                automatically compares the desired state in Git with the cluster. Therefore the drift remains undetected untill
                                another deployment or external monitoring/auditing mechanisms identifies it. 

- No self-healing: If a Git managed kubernetes resources is manually deleted, the CI pipeline doesn't automatically re-apply it unless
                   another deployment or reconciliation mechanism is triggered.

- Audit trail is in CI logs: not always accessible, and if someone manually changes the live cluster via CLI or AWS dashboard
                             it never appears in the CI logs.

- Credentials problem: A long-lived kubeconfig secret is stored in Github secrets for permanent write access to the cluster. If 
                       an attacker manages to intercept this secret gets unrestricted access to the live cluster.

On the other hand, the ArgoCD controller continuously reconciles with the Git repository and Git is the single source of truth.
Any detected drift of kubernetes resources in the live cluster managed by ArgoCD can be reconciled back to the desired state in Git.

- Why App of Apps pattern

Without the App of Apps pattern, each ArgoCD application must be created and managed independently. The App of Apps pattern introduces 
a root application whose desired state consists of child applications. This allows adding a new microservice or platform component 
to the application by adding its child application to the Git repo managed by the root application.

## Tradeoffs:

| Consideration| Upside | Downside |
|---|---|---|
| GitOps vs push-based | Drift detection, self-healing, Git audit trail | needs headroom for argocd components in resource constraint nodes
| App of Apps vs single app | centralized bootstrap and management of multiple Applications | Extra layer of debugging from root app to child app
| ArgoCD selfHeal: true	| Detects and reconciles managed-resource drift | Emergency manual changes may be reverted
| ArgoCD prune: true | Remove resources no longer defined in Git | A bad commit can delete managed resources.
| allowEmpty: false | Protects against accidental removal of all application resources | Prevents empty-state deployments unless explicitly enabled
| Automated sync | Faster Git-to-cluster deployment | Bad changes can propagate automatically without appropriate review gates


## Challenges Encountered:

Github-actions-platform role authorization failure:  The platform role defined for Argocd installation and creation of root app for watching
the app/ authenticated with AWS using AWS IAM role, but failed to authorize with the EKS cluster to perform necessary action.

Resolution: An aws-auth config map is defined using Terraform for Kubernetes RBAC permissions that is, the Github actions platform AWS IAM role 
was granted the minimum kubernetes permissions required to bootstrap ArgoCD and create the root application. AWS now recommends EKS Access 
Entries as the preferred approach for managing IAM principal access to Kubernetes, which is a future improvement for this project.



## Key Takeaways:

- GitOps is a deployment principle for the automatic syncing of application manifests with the live cluster for a smooth operation of 
  the infrasturcture. Git repo is the cluster's desired state and every change to the cluster should go through the Git first.

- Terraform does the bootstrapping of the platform for deployment and then ArgoCD takes control of automatic deployment.

- selfHeal: true, and prune: true makes sure that actual state of the cluster always in sync with desired state of Git repo.

- The resources-finalizer.argocd.argoproj.io finalizer controls cascading deletion of resources managed by an Argo CD Application. 
  For an App of Apps  hierarchy, this can cause deletion of child Application resources and their managed resources when the root 
  Application is deleted. Without cascading deletion, child Applications may remain after the root Application is removed.



  
  