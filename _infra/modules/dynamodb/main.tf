resource "aws_dynamodb_table" "grain_store" {
    name           = "AdventureGrainStore"
    billing_mode   = "PROVISIONED"
    read_capacity  = 10
    write_capacity = 10

    tags = {
        Name = var.name
    }
}

resource "aws_dynamodb_table" "cluster_store" {
    name           = "AdventureClusterStore"
    billing_mode   = "PROVISIONED"
    read_capacity  = 10
    write_capacity = 10

    tags = {
        Name = var.name
    }
}