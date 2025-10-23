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

module "repository" {
  source = "./modules/repository"
  name   = "raven-repository"
}

module "codedeploy" {
  source       = "./modules/codedeploy"
  name         = local.project_name
  github_token = var.github_token
  github_repo  = var.github_repo_url
}

module "s3" {
  source       = "./modules/s3"
  bucket_name  = local.project_name
  api_url      = module.backend.api_gateway_url
}

module "backend" {
  source       = "./modules/backend"
  name  = local.project_name
  default_client_image_url = "${module.repository.repository_url}:client"
  default_server_image_url = "${module.repository.repository_url}:server"
  vpc_id = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  dynamodb_table_arn = module.dynamodb.cluster_table_arn
  dynamodb_table_grain_arn = module.dynamodb.grain_table_arn
}