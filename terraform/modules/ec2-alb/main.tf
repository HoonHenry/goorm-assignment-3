variable "ami" {
  description = "The AMI to use for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "The instance type of the EC2 instance"
  type        = string
}

variable "subnet_ids" {
  description = "The IDs of the subnets to place the EC2 instance in"
  type        = list(string)
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}

resource "aws_security_group" "my_security_group" {
  vpc_id = var.vpc_id

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
    Name = "${var.vpc_name}-sg-1"
  }
}

resource "aws_instance" "my_instance" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.subnet_ids[0]
  vpc_security_group_ids = [
    aws_security_group.my_security_group.id
  ]
  associate_public_ip_address = true

  # ... EC2 configurations ...
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install nginx -y
                EOF

  tags = {
    Name = "${var.vpc_name}-i-1"
  }
}

# ... ALB resources ...
resource "aws_lb" "my_alb" {
  name               = "${var.vpc_name}-alb-1"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = [
    aws_security_group.my_security_group.id
  ]

  tags = {
    Name = "${var.vpc_name}-alb-1"
  }
}

resource "aws_lb_target_group" "my_target_group" {
  name     = "${var.vpc_name}-tg-1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
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

resource "aws_lb_target_group_attachment" "tg_attachment" {
  target_group_arn = aws_lb_target_group.my_target_group.arn
  target_id        = aws_instance.my_instance.id
  port             = 80
}
