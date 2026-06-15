output "cluster_name" {
    value = module.eks.cluster_name
}

output "cluster_endpoint" {
    description = " The endpoint of the EKS cluster"
    value = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
    description = " The certificate authority data for the EKS cluster"
    value = module.eks.cluster_ca_certificate
}

output "cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
  description = "The security group ID associated with the EKS cluster"
}