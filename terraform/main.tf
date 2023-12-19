module "vpc" {
  source      = "./modules/vpc"
  region      = "ap-northeast-2"
  vpc_cidr    = "10.0.0.0/16"
  subnet_cidrs = [
    "10.0.64.0/20", "10.0.80.0/24",
    "10.0.96.0/24", "10.0.112.0/24"
  ]
  az_list = [
    "ap-northeast-2a",
    "ap-northeast-2b",
    "ap-northeast-2c",
    "ap-northeast-2d"
  ]
}

module "ec2_alb" {
  source       = "./modules/ec2-alb"
  ami          = "ami-09eb4311cbaecf89d" # Replace with the correct AMI ID
  instance_type = "t2.micro"
  subnet_ids    = module.vpc.subnet_ids
  vpc_id        = module.vpc.vpc_id
  vpc_name      = module.vpc.vpc_name
}

provider "aws" {
  region = "ap-northeast-2"
}
