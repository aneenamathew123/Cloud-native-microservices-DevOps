output "cluster_name" {
  description = " The name of the EKS cluster"
  value = aws_eks_cluster.EKS_cluster.name
}

output "cluster_endpoint" {
  description = " The endpoint of the EKS cluster"
  value = aws_eks_cluster.EKS_cluster.endpoint
}

output "cluster_ca_certificate" {
  description = " The certificate authority data for the EKS cluster"
  value = aws_eks_cluster.EKS_cluster.certificate_authority[0].data
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.EKS_cluster.vpc_config[0].cluster_security_group_id
  description = "The security group ID associated with the EKS cluster"
}

