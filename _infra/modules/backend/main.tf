
data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "ecs_node_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

data "aws_availability_zones" "available" {}

locals {
    lambda_role_name            = "${var.name}-lambda-role"
    lambda_client_function_name = "${var.name}-client"

    api_gateway_name = "${var.name}-api-gateway"

    aws_ecs_service_name   = "${var.name}-ecs-service"
    aws_ecs_cluster_name   = "${var.name}-ecs-cluster"
    aws_task_def_name      = "${var.name}-server-task-definition"
    aws_ecs_keyapir        = "${var.name}-ecs-keypair" // Created manually
    aws_ecs_container_name = "${var.name}-server-container"

    account_id = data.aws_caller_identity.current.account_id
    
    server_tag_name = "${var.name}-server"
}

################################
# API Gateway 
################################

resource "aws_apigatewayv2_api" "adventure_api" {
  name        = local.api_gateway_name
  description = "Backend API Gateway"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]                   # Replace with your domain for security
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["content-type", "authorization"]
  }
}

resource "aws_apigatewayv2_integration" "adventure_api_integration" {
  api_id                 = aws_apigatewayv2_api.adventure_api.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  description            = "adventure client api"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.adventure_api.invoke_arn
  payload_format_version = "2.0"
  timeout_milliseconds   = 30000
}

resource "aws_apigatewayv2_route" "adventure_api_route" {
  api_id    = aws_apigatewayv2_api.adventure_api.id
  route_key = "ANY /api/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.adventure_api_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.adventure_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.adventure_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.adventure_api.execution_arn}/*/*"
}

################################
# Lambda Function
################################

data "aws_iam_policy_document" "adventure_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "adventure_api_role" {
  name               = "${local.lambda_role_name}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.adventure_assume_role.json
}

resource "aws_iam_role_policy_attachment" "adventure_api_policy" {
  role       = aws_iam_role.adventure_api_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "adventure_api" {
    function_name    = local.lambda_client_function_name
    package_type     = "Image"
    role             = aws_iam_role.adventure_api_role.arn
    image_uri        = var.default_client_image_url
    timeout       = 30
    memory_size   = 256

    environment {
      variables = {
        ENVIRONMENT = "production"
        ASPNETCORE_ENVIRONMENT = "Production"
      }
    }
}

resource "aws_cloudwatch_log_group" "adventure_lambda_logging" {
  name              = "/aws/api/${aws_lambda_function.adventure_api.function_name}"
  retention_in_days = 3
}

###############
# ECS Service
###############

# -------------------------
# ECS Cluster
# -------------------------

resource "aws_ecs_cluster" "adventure_cluster" {
 name = local.aws_ecs_cluster_name
}

# -------------------------
# IAM Role
# -------------------------

resource "aws_iam_role" "adventure_ecs_node_role" {
  name_prefix        = "${local.aws_ecs_service_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_node_role_policy" {
  role       = aws_iam_role.adventure_ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "adventure_ecs_node" {
  name_prefix = "${local.aws_ecs_service_name}-profile"
  role        = aws_iam_role.adventure_ecs_node_role.name
}

# ----------------------------------------------------
# IAM Policy: ECS EC2 Access to CloudWatch
# ----------------------------------------------------
resource "aws_iam_policy" "adventure_ecs_cloudwatch_policy" {
  name        = "ecs-cloudwatch-access"
  description = "Allow ECS instances and tasks to write logs and metrics to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          # CloudWatch Logs
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",

          # CloudWatch Metrics
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",

          # ECS container insights (optional)
          "ec2:DescribeTags",
          "ec2:DescribeInstances"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "adventure_ecs_attach_cloudwatch" {
  role       = aws_iam_role.adventure_ecs_node_role.name
  policy_arn = aws_iam_policy.adventure_ecs_cloudwatch_policy.arn
}

# ----------------------------------------------------
# IAM Policy: ECS EC2 Access to DynamoDb
# ----------------------------------------------------

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
          "dynamodb:DescribeTable"
        ],
        Resource = [
          var.dynamodb_table_arn,
          var.dynamodb_table_grain_arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_attach_orleans_dynamodb" {
  role       = aws_iam_role.adventure_ecs_node_role.name
  policy_arn = aws_iam_policy.ecs_orleans_dynamodb_policy.arn
}
