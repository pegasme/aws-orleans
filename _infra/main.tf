provider "aws" {
  region = "us-east-1"
}

module "vpc" {
    source = "./modules/vpc"
    name   = "orleans"
    region = "us-east-1"
} 