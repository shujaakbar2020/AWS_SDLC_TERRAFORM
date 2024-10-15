# Create VPC
resource "aws_vpc" "demo" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "demo-vpc"
  }
}

# Create Subnets
resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.demo.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.demo.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-2b"
  map_public_ip_on_launch = true
}

# Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.demo.id
}

# Create a route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.demo.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# Associate Route Table with subnets
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.public.id
}

# Create Security Group
resource "aws_security_group" "ecs_sg" {
  name   = "ecs-security-group"
  vpc_id = aws_vpc.demo.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-sg"
  }
}
