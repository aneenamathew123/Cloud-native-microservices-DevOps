variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC to associate with the EKS cluster"
  type        = string
}
variable "public_subnet_ids" {
  description = "The IDs of the public subnets to associate with the EKS cluster"
  type        = list(string)
}
variable "private_subnet_ids" {
  description = "The IDs of the private subnets to associate with the EKS cluster"
  type        = list(string)
}

variable "node_security_group_id" {
  description = "The ID of the security group for the EKS nodes"
  type        = string
}


variable "node_groups" {
  description = "Configuration for the EKS node group"
  type = map(object({
    capacity_type  = string
    instance_types = list(string)
    scaling_config = object({
      desired_size = number
      max_size     = number
      min_size     = number
    })

  }))
}