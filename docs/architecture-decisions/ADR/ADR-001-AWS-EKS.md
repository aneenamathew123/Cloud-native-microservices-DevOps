## Kubernetes on AWS EKS as the Deployment Environment:

The Opentelemetry demo application has a microservice architecture for scalability, flexibilty and resilience.
This architecture consists of 20 microservices written in different programming languages,for instance, Go, Python,
Java, Node.js etc and communicate over gRPC and HTTP protocols.The microservices run as isolated containers and needs
an orchestration manager for high availability, disaster recovery,and handle inter service networking and service discovery.
The deployment environment should also support production-grade observability such as metrics, logs, and traces. It should 
also be reproducible and infrastructure as code friendly.

The three primary options evaluated were bare EC2 instances, Docker compose on a single VM and kubernetes as a managed service.

## Decision:

Use Kubernetes as the container orchestration platform, hosted on AWS Elastic Kubernetes Service (EKS) in eu-west-1.

## Rationale:

- Why kubernetes over Docker Compose

Docker Compose deployment on a single VM concentrates the workload on a single host, creates a single point of failure and 
limiting horizontal scaling, scheduling, and automated recovery across hosts. In contrast, Kubernetes provides:

a) Self healing: The kubelet monitors container health via liveness/readiness probes and restarts failed containers on
                 the same node per pod's restart policy. If a node fails and the node controller detects it and after a 
                 grace period the scheduler reschedules the node's pods onto healthy nodes.

b) Declarative state: The continous reconciliation of cluster state with the desired state as declared in the mainfests.

c) Service Discovery: No need to hardcore IPs, since it supports built in DNS

d) High Availability: Multiple number of replicas combined with pod anti-affinity rules across zones and nodes, make services highly available.

e) Namespace isolation: Workloads, platforms, monitoring resources can be isolated across different environments.

f) Resource management: Management of CPU, memory resources for different services through requests and limits.

g) Observability: Kubernetes provides a consistent platform for deployment and scaling observability components such as Grafana alloy as a 
                  DaemonSet along with application workloaods. Kubernetes metadata can be automatically attached to telemetry via the OTel 
                  Collector's k8sattributesprocessor, making it easier to correlate application telemetry with the originating Pods, 
                  namespaces, nodes, and workloads.

- Why EKS over a self-managed Kubernetes.

Running a self-managed kubernetes such as Kubeadm, K3s on EC2 causes maintenance overhead. The control plane of the 
K8s require backup of etcds or maintaining multiple copies of etcd for failover, upgrading control plane and management 
of certificates. AWS EKS eliminates all of these limitations:
a) AWS manages the control plane, etcd and API server availability.

b) Node groups can be upgraded and can be easily autoscaled based on requirement without any cluster recreation.

c) AWS provides VPC CNI for nodes to communicate without any ovelay networking complexity.

d) EKS exposes an OIDC issuer endpoint, which is registered as an IAM identity in AWS. The IRSA uses this trust relationship to
   pods assume IAM roles via kubernetes service accounts, eliminating the need for long-lived credentials stored in the pods.

- Why AWS over GKE or AKS 

AWS was chosen because it has a wide adoption across the world and AWS EKS extends that experience into a cloud-managed context. 
AWS free-tier and spot pricing also made the project cost-manageable for a portfolio.

## Tradeoffs:

| Consideration| Upside | Downside |
|---|---|---|
| EKS vs self-managed | No control plane maintenance overhead | EKS costs ~$0.10/hr even with no nodes running |
| Kubernetes vs Docker Compose | Work as a Multi services manager in a prod environment, with self-healing and scalability | Significant learning curve |
| Managed node group | AWS manages node lifecycle | Less control over node configuration |
| t3.small node type | Low cost | Requires careful pod scheduling bcoz of memory pressure and pod limit | 

## Challenges Encountered:

- Failed Microservices deployment: The initial deployment on 2*t3.small nodes failed scheduling with a "Too many pods" error. Each t3.small node's
                                   kubelet is bootstrapped with a static max-pods limit of 11, calculated from ENI/IP capacity.

- First attempted fix: Enabled IP prefix delegation on the VPC CNI add-on, expecting it to increase the available pod capacity. This didn't resolve
                       the issue, since prefix delegation increases the available IPs per ENI but doesn't update the max-pod limit dynamically. 

- Resolution: Scaled to 4×t3.small nodes, increasing aggregate cluster pod capacity, which was sufficient for the 20+ microservices and supporting components.

- Unschedulable load generator pod: An Initial memory requests of 1500Mi for the load generator microservice exceeded the allocatable memory available 
                                    on any single t3.small node, leaving the pod in a pending state.

- Resolution: Reduced the memory requests/limits to a value fit within the node capacity, allowing the scheduler to allocate the pod successfully.

- Missing NAT Gateway: Private subnets could not reach Github container registry for pulling images because Terraform module did not provision 
                       a NAT Gateway initially.

- Resolution: added enable_nat_gateway = true to the VPC module configuration.


## Key Takeaways:

- AWS VPC CNI assigns pod IPs directly from VPC CIDR, allowing pods to participate directly in the VPC network without any overlay complexity.

- The resource requests and limits matter operationally, not just theoretically, the memory pressure caused real scheduling failures.

- Choosing small instance types (t3.small) on a free-tier account does not by itself guarantee cost optimization. Fixed-cost components 
  such as NAT Gateway, load balancers, and the EKS control plane are billed independently of node size and run continuously, and 
  together consumed all available credits within a week regardless of the small instance type.

- Cost visibility requires tracking all billable components such as control plane, NAT Gateway, load balancers and running hours from day one 
  and not just the instance type. Destroying the infrastructure promptly when not in active use is essential on a free-tier budget.

