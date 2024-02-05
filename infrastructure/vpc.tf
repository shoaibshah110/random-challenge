provider "aws" {
  region = "us-east-1"
}

# Variables

variable "vpcName" {
  type    = string
  default = "Preprod-Vpc"
}

variable "cidrBlock" {
  type    = string
  default = "10.0.0.0/16"
}

variable "availabilityZoneA" {
  type    = string
  default = "us-east-1a"
}

variable "availabilityZoneB" {
  type    = string
  default = "us-east-1b"
}

# Resources

# VPC
resource "aws_vpc" "preprodVpc" {
  cidr_block           = var.cidrBlock
  enable_dns_hostnames = true
  tags = {
    Name = var.vpcName
  }
}

# Public Subnet 1
resource "aws_subnet" "preprodSubnet1" {
  vpc_id                  = aws_vpc.preprodVpc.id
  cidr_block              = cidrsubnet(aws_vpc.preprodVpc.cidr_block, 8, 1)
  map_public_ip_on_launch = true
  availability_zone       = var.availabilityZoneA
  tags = {
    Name = "Preprod-Public-Subnet-1"
  }
}

# Public Subnet 2
resource "aws_subnet" "preprodSubnet2" {
  vpc_id                  = aws_vpc.preprodVpc.id
  cidr_block              = cidrsubnet(aws_vpc.preprodVpc.cidr_block, 8, 2)
  map_public_ip_on_launch = true
  availability_zone       = var.availabilityZoneB
  tags = {
    Name = "Preprod-Public-Subnet-2"
  }
}

# Internet Gateway - Allows VPC to connect to the internet
resource "aws_internet_gateway" "internetGateway" {
  vpc_id = aws_vpc.preprodVpc.id
  tags = {
    Name = "Internet-Gateway"
  }
}

# Pointing the route 0.0.0.0/0 to the internet gateway - need to attach the route to the subnets
resource "aws_route_table" "routeTable" {
  vpc_id = aws_vpc.preprodVpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internetGateway.id
  }
}

# Attaching routes to both subnet1 and subnet2, making them public as they now have internet connection
resource "aws_route_table_association" "subnet1Association" {
  subnet_id      = aws_subnet.preprodSubnet1.id
  route_table_id = aws_route_table.routeTable.id
}
resource "aws_route_table_association" "subnet2Association" {
  subnet_id      = aws_subnet.preprodSubnet2.id
  route_table_id = aws_route_table.routeTable.id
}

# Both ingress and egress rules allow all inbound and outbound access for any protocol, via any port. This is not good practice for prod (demo purpose)
resource "aws_security_group" "ecsSecurityGroup" {
  name   = "ecs-security-group"
  vpc_id = aws_vpc.preprodVpc.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    self        = "false"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Outputs
output "ecsSecurityGroupID" {
  value       = aws_security_group.ecsSecurityGroup.id
  description = "The ID of ecsSecurityGroup"
}

output "subnet1Id" {
  value       = aws_subnet.preprodSubnet1.id
  description = "Public Subnet 1 ID"
}

output "subnet2Id" {
  value       = aws_subnet.preprodSubnet2.id
  description = "Public Subnet 2 ID"
}

output "vpcID" {
  value       = aws_vpc.preprodVpc.id
  description = "VPC ID"
}