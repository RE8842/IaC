

locals {
  common_tags = {
    Owner = "STS Team"
    service = "backend"
    }
  }

/*  
resource "aws_s3_bucket" "sts" {
    bucket = "stsre-terraform-backend"
    tags = local.common_tags
}

resource "aws_s3_object" "folder" {
  bucket = aws_s3_bucket.sts.id
  key    = "shared/"
}
*/

terraform {
  backend "s3" {
    bucket = "stsre-terraform-backend"
    key    = "shared/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_vpc" "default" {
  cidr_block           = "172.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_eip" "lb" {
  vpc      = true
}

output "eip" {
  value = aws_eip.lb.public_ip
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.default.id
}

variable "sg_ports" {
  type        = list(number)
  description = "list of ingress ports"
  default     = [80, 22]
}

resource "aws_security_group" "dynamicsg" {
  name        = "dynamic-sg"
  description = "Ingress for Vault"

  dynamic "ingress" {
    for_each = var.sg_ports
    iterator = port
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

resource "aws_key_pair" "loginkey" {
  key_name   = "login-key"
  public_key = file("${path.module}/id_rsa.pub")
}

resource "aws_instance" "stsvm" {
   ami = "ami-08e167817c87ed7fd"
   instance_type = "t2.micro"
   key_name = aws_key_pair.loginkey.key_name
   tags = local.common_tags
}
