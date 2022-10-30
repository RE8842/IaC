terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.36.0"
    }
  }
}


provider "aws" {
  profile = "respinoza"
  region = "us-east-1"
}

data "aws_availability_zone" "avzo1" {
  name = "us-east-1a"
}

resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
 

  tags = {
    Name = "MY VPC"
  }
}

resource "aws_subnet" "public_subnet" {
  availability_zone = data.aws_availability_zone.avzo1.name
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.1.0.0/16"

  tags = {
    Name = "public_subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  availability_zone = data.aws_availability_zone.avzo1.name
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.2.0.0/16"

  tags = {
    Name = "private_subnet"
  }
}

resource "aws_instance" "webserver" {
  availability_zone = data.aws_availability_zone.avzo1.name
  ami = "ami-09d3b3274b6c5d4aa"
  instance_type = "t2.large"
  vpc_security_group_ids = [aws_security_group.publicsg.id]
  user_data = file("${path.module}/tieronedata.sh")

  tags = {
    "Name" = "EC2.LA_P"
  }
}

resource "aws_instance" "database" {
  availability_zone = data.aws_availability_zone.avzo1.name
  ami = "ami-09d3b3274b6c5d4aa"
  instance_type = "t2.large"
  user_data = file("${path.module}/tiertwodata.sh")

  tags = {
    "Name" = "EC2.M"
  }
}

resource "aws_security_group" "publicsg" {
  name        = "public-sg"
  description = "Ingress for Vault"
  vpc_id = aws_vpc.myvpc.id

  dynamic "ingress" {
    for_each = var.ports
    iterator = port
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}