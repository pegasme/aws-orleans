
locals {
    lambda_role_name = "${var.name}-lambda-role"
    lambda_function_name = "${var.name}-lambda-function"

    api_gateway_name = "${var.name}-api-gateway"
}

################################
# API Gateway 
################################

resource "aws_api_gateway_rest_api" "adventure_api" {
  name = local.api_gateway_name
  description = "Backend API Gateway"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.adventure_api.id
  parent_id = aws_api_gateway_rest_api.adventure_api.root_resource_id
  path_part = "api"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.adventure_api.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.adventure_api.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type = "AWS"
  uri = aws_lambda_function.adventure_api.invoke_arn
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

resource "aws_lambda_function" "adventure_api" {
    function_name    = local.lambda_role_name
    package_type     = "Image"
    role             = aws_iam_role.adventure_api_role.arn
    image_uri        = var.default_image_url
    timeout       = 30
    memory_size   = 256

    environment {
      variables = {
        ENVIRONMENT = "production"
      }
    }
}