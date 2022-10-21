terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.36.0"
    }
  }
  backend "s3" {
    bucket = "week3demo"
    key = "terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  profile = "respinoza"
  region = "us-east-1"
}

data "aws_key_pair" "demowk3" {
  key_name="demowk3"
}

resource "aws_instance" "stsvm" {
   ami = "ami-09d3b3274b6c5d4aa"
   instance_type = "t2.micro"
   key_name = data.aws_key_pair.demowk3.key_name
   vpc_security_group_ids = [aws_security_group.dynamicsg.id]
   subnet_id = "subnet-0666dccf9543926de"
   tags = {
     "Name" = "EC2"
   }
   user_data = file("${path.module}/userdata.sh")

   #tags = local.common_tags
}

resource "aws_security_group" "dynamicsg" {
  name        = "dynamic-sg"
  description = "Ingress for Vault"
  vpc_id = "vpc-094539794c5fc6b0e"

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



