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