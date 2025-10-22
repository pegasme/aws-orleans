resource "aws_dynamodb_table" "grain_store" {
    name           = "AdventureGrainStore"
    billing_mode   = "PROVISIONED"
    read_capacity  = 10
    write_capacity = 10

    hash_key       = "GrainReference"
    range_key      = "GrainType"

    attribute {
        name = "GrainReference"
        type = "S"
    }
    
    attribute {
        name = "GrainType"
        type = "S"
    }

    ttl {
        attribute_name = "GrainTtl"
        enabled        = true 
    }

    tags = {
        Name = var.name
    }
}

resource "aws_dynamodb_table" "cluster_store" {
    name           = "AdventureClusterStore"
    billing_mode   = "PROVISIONED"
    read_capacity  = 10
    write_capacity = 10

    hash_key       = "DeploymentId"
    range_key      = "SiloIdentity"

    attribute {
        name = "DeploymentId"
        type = "S"
    }
    
    attribute {
        name = "SiloIdentity"
        type = "S"
    }

    tags = {
        Name = var.name
    }
}