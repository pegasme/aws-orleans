locals {
  project_name = "adventure"
}
module "vpc" {
  source = "./modules/vpc"
  name   = local.project_name
  region = var.region
}

module "dynamodb" {
  source = "./modules/dynamodb"
  name   = local.project_name
  region = var.region
}

module "gw" {
  source = "./modules/gateway"
  name   = local.project_name
  vpc_id = module.vpc.vpc_id
}