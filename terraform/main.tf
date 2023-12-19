provider "aws" {
  region = "ap-northeast-2" # Replace with your AWS region
}

resource "aws_security_group" "alb_sg" {
#   name        = "alb-security-group"
  name        = "vpc-alb-1-sg-alb-1"
  description = "Security group for ALB"
#   vpc_id   = "vpc-abcdef" # Replace with your VPC ID
  vpc_id   = "vpc-00de5fd5e04d7d279" # Replace with your VPC ID

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "instance_sg" {
#   name        = "instance-security-group"
  name        = "vpc-alb-1-sg-i-1"
  description = "Security group for EC2 instance"
#   vpc_id   = "vpc-abcdef" # Replace with your VPC ID
  vpc_id   = "vpc-00de5fd5e04d7d279" # Replace with your VPC ID

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "nginx_instance" {
  ami           = "ami-09eb4311cbaecf89d" # Replace with the correct Ubuntu 20.04 AMI for your region
  instance_type = "t2.micro"
  security_groups = [aws_security_group.instance_sg.name]

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install nginx -y
                EOF

  tags = {
    Name = "NginxInstance"
  }
}

resource "aws_lb" "nginx_alb" {
  name               = "nginx-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
#   subnets            = ["subnet-abcde", "subnet-fghij"] # Replace with your subnet IDs
  subnets            = ["subnet-0354ba06505d37a99", "subnet-06617a9057662659b"] # Replace with your subnet IDs

  enable_deletion_protection = false

  tags = {
    Name = "NginxALB"
  }
}

resource "aws_lb_target_group" "nginx_tg" {
  name     = "nginx-target-group"
  port     = 80
  protocol = "HTTP"
#   vpc_id   = "vpc-abcdef" # Replace with your VPC ID
  vpc_id   = "vpc-00de5fd5e04d7d279" # Replace with your VPC ID

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-299"
  }
}

resource "aws_lb_listener" "nginx_listener" {
  load_balancer_arn = aws_lb.nginx_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "nginx_attachment" {
  target_group_arn = aws_lb_target_group.nginx_tg.arn
  target_id        = aws_instance.nginx_instance.id
  port             = 80
}
