
# configure VPC

resource "aws_vpc" "opentelemetry_app_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.cluster_name}-vpc"

  }
}

# configure subnets

resource "aws_subnet" "opentelemetry_public_subnet" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.opentelemetry_app_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.cluster_name}-public-subnet"

  }

}

resource "aws_subnet" "opentelemetry_private_subnet" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.opentelemetry_app_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "${var.cluster_name}-private-subnet"

  }

}

# configure internet gateway
resource "aws_internet_gateway" "opentelemetry_igw" {
  vpc_id = aws_vpc.opentelemetry_app_vpc.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

# Configure NAT gateway




# configure route table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.opentelemetry_app_vpc.id

  route {
    cidr_block = "0.0.0.0/0" # route all traffic to the internet
    gateway_id = aws_internet_gateway.opentelemetry_igw.id
  }
  tags = {
    Name = "${var.cluster_name}-public-route-table"
  }

}
resource "aws_route_table_association" "public_subnet_route_association" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.opentelemetry_public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# configure security group
resource "aws_security_group" "opentelemetry_node_sg" {
  name = "${var.cluster_name}-node-sg"
  vpc_id = aws_vpc.opentelemetry_app_vpc.id
  
  ingress {
    description = "node to node and control plane communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  lifecycle {
    create_before_destroy = true

  }

  tags = {
    Name = "${var.cluster_name}-node-sg"
  }

}
