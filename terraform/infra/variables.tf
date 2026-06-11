variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets"
  type        = list(string)

}
variable "availability_zones" {
  description = "List of availability zones to use for subnets"
  type        = list(string)

}

variable "cluster_name" {
  description = "Name of the EKS cluster"
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