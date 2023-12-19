provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc-alb-2"
  }
}

resource "aws_subnet" "my_subnet_1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.64.0/20"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "vpc-alb-2-subnet-1"
  }
}

resource "aws_subnet" "my_subnet_2" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.80.0/20"
  availability_zone = "ap-northeast-2b"
  tags = {
    Name = "vpc-alb-2-subnet-2"
  }
}

resource "aws_subnet" "my_subnet_3" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.96.0/20"
  availability_zone = "ap-northeast-2c"
  tags = {
    Name = "vpc-alb-2-subnet-3"
  }
}

resource "aws_subnet" "my_subnet_4" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.112.0/20"
  availability_zone = "ap-northeast-2d"
  tags = {
    Name = "vpc-alb-2-subnet-4"
  }
}

resource "aws_security_group" "my_security_group" {
  vpc_id = aws_vpc.my_vpc.id

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpc-alb-2-sg-1"
  }
}

resource "aws_instance" "my_instance" {
#   ami           = "ami-xxxxxxxxxxxx" # Replace with the latest Ubuntu 20.04 AMI ID in ap-northeast-2
  ami           = "ami-09eb4311cbaecf89d" # Replace with the latest Ubuntu 20.04 AMI ID in ap-northeast-2
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.my_subnet_1.id # Use one of the created subnets
  security_groups = [aws_security_group.my_security_group.name]

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install nginx -y
                EOF

  tags = {
    Name = "vpc-alb-2-i-1"
  }
}

resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.my_subnet_1.id, aws_subnet.my_subnet_2.id, aws_subnet.my_subnet_3.id, aws_subnet.my_subnet_4.id]
  security_groups    = [aws_security_group.my_security_group.id]

  tags = {
    Name = "vpc-alb-2-alb-1"
  }
}

resource "aws_lb_target_group" "my_target_group" {
  name     = "vpc-alb-2-tg-1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id
}

resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}
