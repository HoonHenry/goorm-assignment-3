#!/bin/bash

# Define the CIDR blocks
region="ap-northeast-2"
vpc_cidr="10.0.0.0/16"
vpc_name="vpc-alb-1"
subnet_cidr1="10.0.64.0/20"
subnet_cidr2="10.0.80.0/20"
subnet_cidr3="10.0.96.0/20"
subnet_cidr4="10.0.112.0/20"
igw_name="$vpc_name-igw-1"
rtb_name="$vpc_name-rtb-1"

aws ec2 describe-availability-zones --region $region --output text && \

# Create VPC and extract VPC ID
vpc_id=$(aws ec2 create-vpc --cidr-block $vpc_cidr --query 'Vpc.VpcId' --output text) && \
echo "VPC Created with ID: $vpc_id" && \

# Add Name tag to the VPC
aws ec2 create-tags --resources $vpc_id --tags Key=Name,Value=$vpc_name --output text --no-cli-pager && \

# Modify vpc attribute to enable DNS hostnames
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-hostnames "{\"Value\":true}" && \
aws ec2 describe-vpc-attribute --vpc-id $vpc_id --attribute enableDnsHostnames --output text --no-cli-pager && \

# Create Internet Gateway and extract IGW ID
igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text) && \
echo "Internet Gateway Created with ID: $igw_id" && \

# Add Name tag to the Internet Gateway
aws ec2 create-tags --resources $igw_id --tags Key=Name,Value=$igw_name  --output text --no-cli-pager && \

# Attach Internet Gateway to VPC
aws ec2 attach-internet-gateway --vpc-id $vpc_id --internet-gateway-id $igw_id --output text --no-cli-pager && \
echo "Internet Gateway $igw_id attached to VPC $vpc_id" && \

# Function to create a subnet and tag it
create_subnet() {
    local cidr_block=$1
    local tag_value=$2
    local az_name=$3

    local subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block $cidr_block --query 'Subnet.SubnetId' --availability-zone $az_name --output text) && \

    echo "Subnet Created with ID: $subnet_id"

    # Add Name tag to the Subnet
    aws ec2 create-tags --resources $subnet_id --tags Key=Name,Value=$tag_value --output text --no-cli-pager
}

# Create four subnets
create_subnet $subnet_cidr1 "$vpc_name-subnet-1" "ap-northeast-2a" && \
create_subnet $subnet_cidr2 "$vpc_name-subnet-2" "ap-northeast-2b" && \
create_subnet $subnet_cidr3 "$vpc_name-subnet-3" "ap-northeast-2c" && \
create_subnet $subnet_cidr4 "$vpc_name-subnet-4" "ap-northeast-2d" && \

# Create a Route Table and extract RTB ID
rtb_id=$(aws ec2 create-route-table --vpc-id $vpc_id --query 'RouteTable.RouteTableId' --output text) && \
echo "Route Table Created with ID: $rtb_id" && \

# Add Name tag to the Route Table
aws ec2 create-tags --resources $rtb_id --tags Key=Name,Value=$rtb_name --output text --no-cli-pager && \

# Create route to the Internet Gateway
aws ec2 create-route --route-table-id $rtb_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id --output text --no-cli-pager && \
echo "Route to IGW $igw_id created in Route Table $rtb_id" && \

# Associate the Route Table with each Subnet
associate_route_table() {
    local subnet_tag=$1
    local subnet_id=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$subnet_tag" --query 'Subnets[0].SubnetId' --output text) && \
    aws ec2 associate-route-table --route-table-id $rtb_id --subnet-id $subnet_id --no-cli-pager && \
    echo "Route Table $rtb_id associated with Subnet $subnet_id"
}

# Associate route table with all subnets
associate_route_table "$vpc_name-subnet-1" && \
associate_route_table "$vpc_name-subnet-2" && \
associate_route_table "$vpc_name-subnet-3" && \
associate_route_table "$vpc_name-subnet-4" && \

echo "AWS VPC, Subnets, Internet Gateway, and Route Table have been created successfully."
