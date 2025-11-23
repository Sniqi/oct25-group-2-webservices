terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Backend configuration will be added later for remote state (S3)
  # backend "s3" { ... }
}

provider "aws" {
  region = "eu-central-1"
}

module "vpc" {
  source      = "../../modules/vpc"
  environment = "dev"
  vpc_cidr    = "10.0.0.0/16"
}

module "ec2" {
  source        = "../../modules/ec2"
  environment   = "dev"
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.public_subnet_id
  instance_type = "t2.micro" # Free Tier eligible
}

output "app_url" {
  value = "http://${module.ec2.public_ip}"
}
