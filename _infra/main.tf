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
}

module "backend" {
  source       = "./modules/backend"
  name  = local.project_name
  default_image_url = "${var.region}.amazonaws.com/${module.repository.repository_name}:client"
}