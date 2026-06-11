output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.opentelemetry_app_vpc.id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = aws_subnet.opentelemetry_public_subnet[*].id
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = aws_subnet.opentelemetry_private_subnet[*].id
}

output "node_security_group_id" {
  description = "The ID of the security group for the EKS nodes"
  value       = aws_security_group.opentelemetry_node_sg.id
}