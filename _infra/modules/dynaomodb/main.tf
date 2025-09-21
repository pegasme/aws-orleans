resource "aws_dynamodb_table" "adventure-dynamodb-table" {
    name           = "AdventureDb"
    billing_mode   = "PROVISIONED"
    read_capacity  = 10
    write_capacity = 10
    hash_key       = "PK"
    range_key      = "SK"

    attribute {
        name = "PK"
        type = "S"
    }

    attribute {
        name = "SK"
        type = "S"
    }

    attribute {
        name = "GSI1-PK"
        type = "S"
    }

    attribute {
        name = "GSI1-SK"
        type = "S"
    }

    ttl {
        attribute_name = "ttl"
        enabled        = true 
    }

    global_secondary_index {
        name               = "GSI"
        hash_key           = "GSI1-PK"
        range_key          = "GSI1-SK"  
        write_capacity     = 10
        read_capacity      = 10
        projection_type    = "INCLUDE"
    }

    tags = {
        Name = var.name
  }
}