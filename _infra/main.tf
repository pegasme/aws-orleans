module "vpc" {
    source = "./modules/vpc"
    name   = vars.project_name
    region = var.region
} 

module dynamodb {
    source = "./modules/dynamodb"
    name   = vars.project_name
    region = var.region
}

module gw {
    source  = "./modules/gateway"
    name    = vars.project_name
    vpc_id  = vpc.vpc_id
}