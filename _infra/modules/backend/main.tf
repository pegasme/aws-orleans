
locals {
    lambda_role_name = "${var.name}-lambda-role"
    lambda_client_function_name = "${var.name}-client"

    api_gateway_name = "${var.name}-api-gateway"
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
  integration_uri        = aws_lambda_function.adventure_api.invoke_arn
  payload_format_version = "2.0"
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
  function_name = aws_lambda_function.example.function_name
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
    image_uri        = var.default_image_url
    timeout       = 30
    memory_size   = 256

    environment {
      variables = {
        ENVIRONMENT = "production"
      }
    }
}