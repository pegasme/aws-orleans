locals {
  project_name = "adventure"
}

module "vpc" {
  source = "./modules/vpc"
  name   = local.project_name
  region = var.region
  environment = var.environment
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

module "s3" {
  source       = "./modules/s3"
  bucket_name  = local.project_name
  api_url      = module.backend.alb_dns_name
}

module "backend" {
  source       = "./modules/backend"
  name  = local.project_name
  default_client_image_url = "${module.repository.repository_url}:client"
  default_server_image_url = "${module.repository.repository_url}:server"
  vpc_id = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  dynamodb_table_grain_arn = module.dynamodb.grain_table_arn
  dynamodb_cluster_table_arn = module.dynamodb.cluster_table_arn
  dynamodb_cluster_table_name = module.dynamodb.cluster_table_name
  dynamodb_grain_table_name = module.dynamodb.grain_table_name
  api_cpu = var.api_cpu
  api_memory = var.api_memory
  orleans_cpu = var.orleans_cpu
  orleans_memory = var.orleans_memory
}