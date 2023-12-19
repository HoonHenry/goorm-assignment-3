#!/bin/bash

# Define the CIDR blocks
vpc_cidr="10.0.0.0/16"
vpc_name="vpc-alb-2"
subnet_cidr1="10.0.128.0/20"
subnet_cidr2="10.0.144.0/20"
subnet_cidr3="10.0.160.0/20"
subnet_cidr4="10.0.176.0/20"
igw_name="vpc-alb-1-igw-2"
rtb_name="vpc-alb-1-rtb-2"

# Create VPC and extract VPC ID
vpc_id=$(aws ec2 create-vpc --cidr-block $vpc_cidr --query 'Vpc.VpcId' --output text) && \
echo "VPC Created with ID: $vpc_id" && \

# Add Name tag to the VPC
aws ec2 create-tags --resources $vpc_id --tags Key=Name,Value=$vpc_name --output text && \

# Modify vpc attribute to enable DNS hostnames
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-hostnames "{\"Value\":true}" && \
aws ec2 describe-vpc-attribute --vpc-id $vpc_id --attribute enableDnsHostnames --output text && \


# Create Internet Gateway and extract IGW ID
igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text) && \
echo "Internet Gateway Created with ID: $igw_id" && \

# Add Name tag to the Internet Gateway
aws ec2 create-tags --resources $igw_id --tags Key=Name,Value=$igw_name  --output text&& \

# Attach Internet Gateway to VPC
aws ec2 attach-internet-gateway --vpc-id $vpc_id --internet-gateway-id $igw_id && \
echo "Internet Gateway $igw_id attached to VPC $vpc_id" && \

# Function to create a subnet and tag it
create_subnet() {
    local cidr_block=$1
    local tag_value=$2
    local subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block $cidr_block --query 'Subnet.SubnetId' --output text)
    echo "Subnet Created with ID: $subnet_id"

    # Add Name tag to the Subnet
    aws ec2 create-tags --resources $subnet_id --tags Key=Name,Value=$tag_value
}

# Create four subnets
create_subnet $subnet_cidr1 "vpc-alb-2-subnet-1" && \
create_subnet $subnet_cidr2 "vpc-alb-2-subnet-2" && \
create_subnet $subnet_cidr3 "vpc-alb-2-subnet-3" && \
create_subnet $subnet_cidr4 "vpc-alb-2-subnet-4" && \

# Create a Route Table and extract RTB ID
rtb_id=$(aws ec2 create-route-table --vpc-id $vpc_id --query 'RouteTable.RouteTableId' --output text) && \
echo "Route Table Created with ID: $rtb_id" && \

# Add Name tag to the Route Table
aws ec2 create-tags --resources $rtb_id --tags Key=Name,Value=$rtb_name && \

# Create route to the Internet Gateway
aws ec2 create-route --route-table-id $rtb_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id && \
echo "Route to IGW $igw_id created in Route Table $rtb_id" && \

# Associate the Route Table with each Subnet
associate_route_table() {
    local subnet_tag=$1
    local subnet_id=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$subnet_tag" --query 'Subnets[0].SubnetId' --output text)
    aws ec2 associate-route-table --route-table-id $rtb_id --subnet-id $subnet_id
    echo "Route Table $rtb_id associated with Subnet $subnet_id"
}

# Associate route table with all subnets
associate_route_table "vpc-alb-2-subnet-1" && \
associate_route_table "vpc-alb-2-subnet-2" && \
associate_route_table "vpc-alb-2-subnet-3" && \
associate_route_table "vpc-alb-2-subnet-4" && \

echo "AWS VPC, Subnets, Internet Gateway, and Route Table have been created successfully."
