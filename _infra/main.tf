module "vpc" {
    source = "./modules/vpc"
    name   = "adventure"
    region = var.region
} 

module dynamodb {
    source = "./modules/dynamodb"
    name   = "adventure"
    region = var.region
}

module gw {
    source  = "./modules/gateway"
    name    = "adventure"
    vpc_id  = vpc.vpc_id
}