variable "region" {
  description = "The AWS region to create resources in"
  type        = string
}

variable "az_list" {
  description = "List of availability zones for the subnets"
  type        = list(string)
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "subnet_cidrs" {
  description = "List of CIDR blocks for the subnets"
  type        = list(string)
}

resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "vpc-alb-2"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "${aws_vpc.my_vpc.tags["Name"]}-igw-1"
  }
}

resource "aws_route" "route" {
  route_table_id            = aws_vpc.my_vpc.default_route_table_id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.my_igw.id
}

resource "aws_subnet" "my_subnets" {
  count = length(var.subnet_cidrs)

  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet_cidrs[count.index]
  availability_zone = var.az_list[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${aws_vpc.my_vpc.tags["Name"]}-subnet-${count.index}"
  }
}

output "vpc_id" {
  value = aws_vpc.my_vpc.id
}

output "vpc_name" {
  value = aws_vpc.my_vpc.tags["Name"]
}

output "subnet_ids" {
  value = aws_subnet.my_subnets.*.id
}
