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

resource "aws_iam_policy" "ecs_orleans_dynamodb_policy" {
  name        = "ecs-orleans-dynamodb-access"
  description = "Allow ECS (Orleans) to use DynamoDB for clustering and storage"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:DescribeTable",
          "dynamodb:CreateTable"
        ],
        Resource = [
          aws_dynamodb_table.cluster_store.arn,
          aws_dynamodb_table.grain_store.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_attach_orleans_dynamodb" {
  role       = var.ecs_instance_role_name
  policy_arn = aws_iam_policy.ecs_orleans_dynamodb_policy.arn
}