#create an iam role for EKS cluster for managing cluster resources.
resource "aws_iam_role" "EKS_cluster_role" {
    name = "${var.cluster_name}-eks-cluster-role"
    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
            Service = "eks.amazonaws.com"
        }
        }
    ]   
    })
    
}
#Attach the policy for setting up permissions to manage EKS cluster resources to the role.
resource "aws_iam_role_policy_attachment" "EKS_cluster_role_attachment" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role       = aws_iam_role.EKS_cluster_role.name
}

#Create the EKS cluster and associate it with the VPC for networking.
resource "aws_eks_cluster" "EKS_cluster" {
    name = "${var.cluster_name}"
    role_arn = aws_iam_role.EKS_cluster_role.arn

vpc_config {
 subnet_ids = var.private_subnet_ids
  }
depends_on = [aws_iam_role_policy_attachment.EKS_cluster_role_attachment]


}

data "aws_caller_identity" "current" {}

#create an iam role for EKS node group to manage worker nodes.
resource "aws_iam_role" "EKS_node_group_role" {
    name = "${var.cluster_name}-eks-node-group-role"
    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
            Service = "ec2.amazonaws.com"
        }
        }
    ]   
    })      

}
# Attach policy to the node group role for managing worker nodes in the EKS cluster.
resource "aws_iam_role_policy_attachment" "EKS_node_group_role_attachment" {
    for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])
    policy_arn = each.value
    role       = aws_iam_role.EKS_node_group_role.name
}

#Create a node group for the EKS cluster to manage worker nodes.
resource "aws_eks_node_group" "EKS_node_group" {
    for_each = var.node_groups
    cluster_name = aws_eks_cluster.EKS_cluster.name
    node_group_name = "${var.cluster_name}-${each.key}"
    node_role_arn = aws_iam_role.EKS_node_group_role.arn
    subnet_ids = var.private_subnet_ids
   # instance_types = each.value.instance_types
    capacity_type = each.value.capacity_type    
   scaling_config {
    desired_size = each.value.scaling_config.desired_size
    max_size     = each.value.scaling_config.max_size
    min_size     = each.value.scaling_config.min_size
  }
  launch_template{
    id = aws_launch_template.EKS_node_group_launch_template[each.key].id
    version = "$Latest"
  }
  depends_on = [aws_iam_role_policy_attachment.EKS_node_group_role_attachment,
                  aws_iam_service_linked_role.EKS_node_group_linked_role, kubernetes_config_map_v1_data.aws_auth]
}

resource "aws_launch_template" "EKS_node_group_launch_template" {
  for_each = var.node_groups
  name_prefix   = "${var.cluster_name}-${each.key}-launch-template"
  instance_type = each.value.instance_types[0]
  vpc_security_group_ids = [var.node_security_group_id]
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"    # IMDSv2 — security best practice
    http_put_response_hop_limit = 1
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_service_linked_role" "EKS_node_group_linked_role" {
  aws_service_name = "eks-nodegroup.amazonaws.com"
  description      = "Service linked role for EKS node groups"
}

resource "kubernetes_config_map_v1_data" "aws_auth" {
  depends_on = [aws_eks_cluster.EKS_cluster]
  metadata {
    name = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    maproles = yamlencode([
      {
      rolearn = aws_iam_role.EKS_node_group_role.arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = ["system:bootstrappers", "system:nodes"]
      }

    ])

    }
  }


