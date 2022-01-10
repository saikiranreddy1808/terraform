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
  region="us-east-2"
}

#1) create a vpc
resource "aws_vpc" "ownvpc" {
  cidr_block = "10.0.0.0/16"
  tags={
    Name="own-vpc"
  }
}

#2)crate a subnet
resource "aws_subnet" "ownsubnet" {
  vpc_id     = aws_vpc.ownvpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "own-subnet"
  }
}
#3) igw
resource "aws_internet_gateway" "ownigw" {
  vpc_id = aws_vpc.ownvpc.id

  tags = {
    Name = "own-igw"
  }
}
#4) route table
resource "aws_route_table" "ownrt" {
  vpc_id = aws_vpc.ownvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ownigw.id
  }
  tags={
    Name: "own-rt"
  }
}
#5) associate rt
resource "aws_route_table_association" "rta_subnet" {
  subnet_id      = aws_subnet.ownsubnet.id
  route_table_id = aws_route_table.ownrt.id
}
#6) security rule
resource "aws_security_group" "mywebsecurity" {
  name        = "ownsecurityrules"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.ownvpc.id

   ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.ownvpc.cidr_block]
  }


  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}
#7) ec2-instance
data "aws_ami" "my-ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"] # Canonical
}
resource "aws_instance" "webserver" {
  ami           = data.aws_ami.my-ami.id
  instance_type = "t2.micro"
   associate_public_ip_address =true
   subnet_id=aws_subnet.ownsubnet.id
   vpc_security_group_ids = [aws_security_group.mywebsecurity.id]
   key_name="k8s"
   user_data=file("server-script.sh")
  
  tags = {
    Name = "mywebserver"
  }
}

output "ip" {
   value = aws_instance.webserver.private_ip
}