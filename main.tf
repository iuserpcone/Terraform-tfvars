
# Configure the AWS Provider
provider "aws" {
  region = var.region_name
}

resource "aws_vpc" "tera-vpc" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "tera-sub" {
  vpc_id            = aws_vpc.tera-vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.subnet_az
  tags = {
    Name = var.public_subnet_name
  }
}

resource "aws_internet_gateway" "tera-gw" {
  vpc_id = aws_vpc.tera-vpc.id

  tags = {
    Name = var.igw_name
  }
}

resource "aws_route_table" "tera-rt" {
  vpc_id = aws_vpc.tera-vpc.id

  route {
    cidr_block = var.route_cidr_block
    gateway_id = aws_internet_gateway.tera-gw.id
  }

  tags = {
    Name = var.route_table_name
  }
}
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.tera-sub.id
  route_table_id = aws_route_table.tera-rt.id
}

resource "aws_security_group" "SG" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.tera-vpc.id

  tags = {
    Name = var.security_group_name
  }
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
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_instance" "Production" {
  ami                         = "ami-00bb6a80f01f03502"
  instance_type               = var.ec2_type
  availability_zone           = var.ec2_az
  subnet_id                   = aws_subnet.tera-sub.id
  vpc_security_group_ids      = [aws_security_group.SG.id]
  associate_public_ip_address = true
  tags = {
    Name = var.public_instance_name
  }
}