
locals {
    lambda_role_name = "${var.name}-lambda-role"
    lambda_client_function_name = "${var.name}-client"

    api_gateway_name = "${var.name}-api-gateway"

    aws_ecs_service_name = "${var.name}-ecs-service"
    aws_ecs_cluster_name = "${var.name}-ecs-cluster"
    
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
    image_uri        = var.default_image_url
    timeout       = 30
    memory_size   = 256

    environment {
      variables = {
        ENVIRONMENT = "production"
      }
    }
}

###############
# ECS Service
###############

resource "aws_ecs_cluster" "adventure_cluster" {
 name = local.aws_ecs_cluster_name
}

resource "aws_ecs_service" "adventure-server" {
  name            = local.aws_ecs_service_name
  desired_count   = 1

  tags = {
   name = local.server_tag_name
 }
}

resource "aws_vpc" "adventure-server-vpc" {
 cidr_block           = var.vpc_cidr
 
 tags = {
   name = local.server_tag_name
 }
}

resource "aws_subnet" "subnet" {
 vpc_id                  = aws_vpc.adventure-server-vpc.id
 cidr_block              = cidrsubnet(aws_vpc.adventure-server-vpc.cidr_block, 8, 1)
 map_public_ip_on_launch = true
 availability_zone       = "us-east-1a"
}

resource "aws_subnet" "subnet2" {
 vpc_id                  = aws_vpc.adventure-server-vpc.id
 cidr_block              = cidrsubnet(aws_vpc.adventure-server-vpc.cidr_block, 8, 2)
 map_public_ip_on_launch = true
 availability_zone       = "us-east-1b"
}

# EC2

resource "aws_security_group" "adventure_server_security_group" {
 name   = "${local.aws_ecs_service_name}-sg"
 vpc_id = aws_vpc.adventure-server-vpc.id
}

resource "aws_launch_template" "adventure_server_ecs_lt" {
 name_prefix   = "${local.aws_ecs_service_name}-template"
 image_id      = "ami-062c116e449466e7f"
 instance_type = "t3.micro"

 key_name               = "ec2ecsglog"
 vpc_security_group_ids = [aws_security_group.adventure_server_security_group.id]
 
 iam_instance_profile {
   name = "ecsInstanceRole"
 }

 block_device_mappings {
   device_name = "/dev/xvda"
   ebs {
     volume_size = 30
     volume_type = "gp2"
   }
 }

 tag_specifications {
   resource_type = "instance"
   tags = {
     Name = "ecs-instance"
   }
 }

 user_data = filebase64("${path.module}/ecs.sh")
}

resource "aws_autoscaling_group" "adventure_server_ecs_asg" {
 vpc_zone_identifier = [aws_subnet.subnet.id, aws_subnet.subnet2.id]
 desired_capacity    = 2
 max_size            = 2
 min_size            = 1

 launch_template {
   id      = aws_launch_template.adventure_server_ecs_lt.id
   version = "$Latest"
 }

 tag {
   key                 = "AmazonECSManaged"
   value               = true
   propagate_at_launch = true
 }
}