
provider "aws" {
region = "eu-west-2"
}

resource "aws_vpc" "prod_vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
      "Name" = "prod_vpc"
    }
  
}

resource "aws_subnet" "prod_subnet01" {
    cidr_block = "10.0.0.0/24"
    vpc_id = aws_vpc.prod_vpc.id
    availability_zone = "eu-west-2a"

    tags = {
      "Name" = "prod_server01"
    }
  
}

# Security group
resource "aws_security_group" "allow_web" {
  name        = "allow_https"
  description = "Allow https inbound traffic"
  vpc_id      = aws_vpc.prod_vpc.id

  ingress {
    description = "Allow HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH from VPC"
    from_port   = 22
    to_port     = 22
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
    Name = "allow_web"
  }
}

resource "aws_internet_gateway" "prod_IG" {
   vpc_id = aws_vpc.prod_vpc.id
}


resource "aws_route_table" "prod_route-table" {
   vpc_id = aws_vpc.prod_vpc.id

tags = {
  Name = "prod"
 }

}

resource "aws_network_interface" "prod_network" {
  subnet_id      = aws_subnet.prod_subnet01.id
  private_ip    = "10.0.1.50"
  security_groups = [aws_security_group.allow_web.id]

}


# Create EC2 ubuntu instance 
resource "aws_instance" "prod_webserver" {
instance_type = "t2.micro"
ami = "ami-005383956f2e5fb96"
availability_zone = "eu-west-2a"
key_name = "kosi-key"

network_interface {
network_interface_id = aws_network_interface.prod_network.id
device_index         = 0
}

 user_data =<<EOF
  #!/bin/bash 
  sudo apt update -y
  sudo apt install apache2 -y 
  sudo  systemctl start apache2 -y 
  sudo echo "My first web server is launched" > /var/www/html/index.html 
  EOF

tags = {
  Name = "Web-server"
}

}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.prod_webserver.id
  allocation_id = aws_eip.EIP.id
  dns = true
 
}

resource "aws_eip" "EIP" {
  vpc = true
}






