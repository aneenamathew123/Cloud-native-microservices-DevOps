vpc_cidr            = "10.0.0.0/16"
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnet_cidrs  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
availability_zones         = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
cluster_name               = "opentelemetry-kubernetes-cluster"
node_groups = {
  general = {
    capacity_type  = "ON_DEMAND"
    instance_types = ["t3.small"]
    scaling_config = {
      desired_size = 2
      max_size     = 2
      min_size     = 1
    }

  }
}



