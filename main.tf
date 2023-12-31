provider "aws" {
  region  = "us-west-2"
  access_key = ""     # Replace with your IAM user's access key
  secret_key = ""     # Replace with your IAM user's secret key
}

#Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "my_vpc"
  }
}

#Create Public subnet #1
resource "aws_subnet" "Public_sub2a" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-west-2a"

  tags = {
    Name = "Public_sub2a"
  }
}

#Create Public subnet #2
resource "aws_subnet" "Public_sub2b" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-west-2b"

  tags = {
    Name = "Public_sub2b"
  }
}

#Create Private subnet #1
resource "aws_subnet" "private_sub2a" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-west-2a"

  tags = {
    Name = "Private_sub2a"
  }
}

#Create Private subnet #2
resource "aws_subnet" "Private_sub2b" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-west-2b"
  map_public_ip_on_launch = false
  tags = {
    Name = "Private_sub2b"
  }
}

#Create Internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "main_IGW"
  }
}

#Create Route Table for Public Subnets
resource "aws_route_table" "my_rt_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "My_Route_Table"
  }
}

#Associate public subnets with routing table
resource "aws_route_table_association" "Public_sub1_Route_Association" {
  subnet_id      = aws_subnet.Public_sub2a.id
  route_table_id = aws_route_table.my_rt_table.id
}

resource "aws_route_table_association" "Public_sub2_Route_Association" {
  subnet_id      = aws_subnet.Public_sub2b.id
  route_table_id = aws_route_table.my_rt_table.id
}

#Create Security group for VPC
resource "aws_security_group" "my_vpc_sg" {
  name        = "my_vpc_sg"
  description = "Allow inbound traffic to instance"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}


#Create EC2 instances in privatesubnets
resource "aws_instance" "private2a_ec2" {
  ami                         = "ami-08e8d3a3c2a73ae76"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_private_sub2a.id
  security_groups             = [aws_security_group.my_vpc_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    sudo usermod -aG docker ec2-user
    sudo systemctl restart docker
    sudo docker run -itd -p 80:8080 testingkyaw/petclinic:4.0
    EOF
}

resource "aws_instance" "private2b_ec2" {
  ami                         = "ami-08e8d3a3c2a73ae76"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.private_sub2b.id
  security_groups             = [aws_security_group.my_vpc_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    sudo usermod -aG docker ec2-user
    sudo systemctl restart docker
    sudo docker run -itd -p 80:8080 testingkyaw/petclinic:4.0
    EOF
}

#Create an ALB target group
resource "aws_lb_target_group" "alb-TG" {
  name     = "alb-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id
}

#Create Load balancer
resource "aws_lb" "my-aws-alb" {
  name               = "my-aws-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.my_vpc_sg.id]
  subnets            = [aws_subnet.Public_sub2a.id, aws_subnet.Public_sub2b.id]
}

# Create Load balancer listner rule
resource "aws_lb_listener" "lb_lst" {
  load_balancer_arn = aws_lb.my-aws-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-TG.arn
  }
}

#Load balancer-Target group attachment
resource "aws_lb_target_group_attachment" "my-aws-alb" {
  target_group_arn = aws_lb_target_group.alb-TG.arn
  target_id        = aws_instance.Pub2a_ec2.id
  port             = 80
}

