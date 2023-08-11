# Add provider
provider "aws" {
  region = "us-east-1"
  
}

# VPC
resource "aws_vpc" "github-actions-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "github-actions-vpc"
  }
}

# Subnet
# Refer http://blog.itsjustcode.net/blog/2017/11/18/terraform-cidrsubnet-deconstructed/
resource "aws_subnet" "github-actions-subnet" {
  vpc_id                  = aws_vpc.github-actions-vpc.id
  cidr_block              = cidrsubnet(aws_vpc.github-actions-vpc.cidr_block, 3, 1)
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

# Security Group

resource "aws_security_group" "cloudsky-ingress-all" {
  name   = "cloudsky-ingress-allow-all"
  vpc_id = aws_vpc.github-actions-vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Terraform requires egress to be defined as it is disabled by default..
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# EC2 Instance for testing
resource "aws_instance" "github-actions-ec2" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  key_name               = var.ami_key_pair
  subnet_id              = aws_subnet.github-actions-subnet.id
  vpc_security_group_ids = [aws_security_group.cloudsky-ingress-all.id]
  tags = {
    Name = "github-actions-ec2"
  }
}

# To access the instance, we would need an elastic IP
resource "aws_eip" "github-actions-eip" {
  instance = aws_instance.github-actions-ec2.id
  vpc      = true
}

# Route traffic from internet to the vpc
resource "aws_internet_gateway" "github-actions-igw" {
  vpc_id = aws_vpc.github-actions-vpc.id
  tags = {
    Name = "github-actions-igw"
  }
}

# Setting up route table
resource "aws_route_table" "github-actions-rt" {
  vpc_id = aws_vpc.github-actions-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.github-actions-igw.id
  }

  tags = {
    Name = "github-actions-rt"
  }
}

# Associate the route table with the subnet
resource "aws_route_table_association" "github-actions-rt-assoc" {
  subnet_id      = aws_subnet.github-actions-subnet.id
  route_table_id = aws_route_table.github-actions-rt.id
}




