module "vpc" {
    source = "./modules/vpc"
    name   = "adventure"
    region = var.region
} 

module dynamodb {
    source = "./modules/dynaomodb"
    name   = "adventure"
    region = var.region
}