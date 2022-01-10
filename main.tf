terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.70.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region="ap-south-1"
}
variable "aws_type" {
  description = "aws instance type"
}
resource "aws_instance" "tf-2" {
  ami           = "ami-052cef05d01020f1d"
  instance_type = var.aws_type

  tags = {
    Name = "mytfinstance"
  }
}

output "instance-ip"{
  value = aws_instance.tf-2.public_ip
}

output "private-ip" {
  value = aws_instance.tf-2.private_ip
}