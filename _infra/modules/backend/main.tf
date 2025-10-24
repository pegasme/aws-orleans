
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
  name          = local.api_gateway_name
  description   = "Backend API Gateway"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"] # Replace with your domain for security
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

resource "aws_iam_policy" "adventure_api_services_policy" {
  name        = "client-api-aws-services-access"
  description = "Allow Lambda client to use DynamoDB for storage"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:DescribeTable",
          "dynamodb:DescribeTimeToLive"
        ],
        Resource = [
          var.dynamodb_table_arn
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ],
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "adventure_api_dynamo_policy" {
  role       = aws_iam_role.adventure_api_role.name
  policy_arn = aws_iam_policy.adventure_api_services_policy.arn
}

resource "aws_lambda_function" "adventure_api" {
  function_name = local.lambda_client_function_name
  package_type  = "Image"
  role          = aws_iam_role.adventure_api_role.arn
  image_uri     = var.default_client_image_url
  timeout       = 30
  memory_size   = 256

  vpc_config {
    subnet_ids = var.public_subnet_ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      ASPNETCORE_ENVIRONMENT = "Production"
      ORLEANS_CLUSTER_ID     = "prod"
      ORLEANS_SERVICE_ID     = "AdventureApp"
      ClusterTableName       = "AdventureClusterStore"
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

resource "aws_ecs_service" "adventure-server" {
  name            = local.aws_ecs_service_name
  desired_count   = 1
  task_definition = aws_ecs_task_definition.adventure_server_task_definition.arn
  cluster         = aws_ecs_cluster.adventure_cluster.id
  launch_type     = "EC2"

  depends_on = [
    aws_autoscaling_group.adventure_server_ecs_asg
  ]

  tags = {
    name = local.server_tag_name
  }
}

# -------------------------
# IAM Role
# -------------------------

resource "aws_iam_role" "adventure_ecs_node_role" {
  name_prefix = "${local.aws_ecs_service_name}-role"

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
          "dynamodb:UpdateTable",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:DescribeTable",
          "dynamodb:DescribeTimeToLive"
        ],
        Resource = [
          var.dynamodb_table_arn,
          var.dynamodb_table_grain_arn
        ]
      },
      # CloudWatch Logs access
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        Resource = "arn:aws:logs:us-east-1:123456789012:log-group:/ecs/*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_attach_orleans_dynamodb" {
  role       = aws_iam_role.adventure_ecs_node_role.name
  policy_arn = aws_iam_policy.ecs_orleans_dynamodb_policy.arn
}

# ------------------------------------------------
# ECS TASK DEFINITIONs
# ------------------------------------------------

resource "aws_cloudwatch_log_group" "ecs_app" {
  name              = "/ecs/${local.aws_task_def_name}"
  retention_in_days = 3
}

resource "aws_iam_role" "adventure_ecs_task_execution_role" {
  name = "${var.name}-server-ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "adventure_ecs_task_execution_role_policy" {
  role       = aws_iam_role.adventure_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "adventure_server_task_definition" {
  family             = local.aws_task_def_name
  cpu                = 256
  memory             = 512
  network_mode       = "bridge"
  execution_role_arn = aws_iam_role.adventure_ecs_task_execution_role.arn

  depends_on = [aws_cloudwatch_log_group.ecs_app]
  
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([{
    name      = local.aws_ecs_container_name
    image     = var.default_server_image_url
    essential = true
    memory    = 512
    portMappings = [
      { "containerPort" : 11111, "hostPort" : 11111, "protocol": "tcp" },
      { "containerPort" : 30000, "hostPort" : 30000, "protocol": "tcp" },
      { "containerPort": 8080, "hostPort": 8080, "protocol": "tcp" }
    ],
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         : aws_cloudwatch_log_group.ecs_app.name,
        "awslogs-region"        : "us-east-1"
        "awslogs-stream-prefix" : "ecs",
        "awslogs-create-group"  : "true"
      }
    },
    enable_cloudwatch_logging = true,
    cloudwatch_log_group_retention_in_days = 3,
    environment = [
      { "name" : "ASPNETCORE_ENVIRONMENT", "value" : "Production" },
      { "name" : "ORLEANS_CLUSTER_ID", "value" : "ecs-orleans-cluster" },
      { "name" : "ORLEANS_SERVICE_ID", "value" : "ecs-orleans-service" },
      { "name": "ORLEANS_SILO_PORT", "value": "11111" },
      { "name": "ORLEANS_GATEWAY_PORT", "value": "30000" },
      { "name" : "AWS_REGION", "value" : "us-east-1" }
    ]
  }])
}

# -------------------------
# Auto Scaling Group
# -------------------------

resource "aws_autoscaling_group" "adventure_server_ecs_asg" {
  name                = "${local.aws_ecs_service_name}-asg"
  vpc_zone_identifier = var.public_subnet_ids
  desired_capacity    = 1
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

resource "aws_launch_template" "adventure_server_ecs_lt" {
  name_prefix   = "${local.aws_ecs_service_name}-tmpl"
  image_id      = data.aws_ssm_parameter.ecs_node_ami.value
  instance_type = "t3.micro"
  key_name      = local.aws_ecs_keyapir

  iam_instance_profile {
    name = aws_iam_instance_profile.adventure_ecs_node.name
  }

  network_interfaces {
    security_groups             = [aws_security_group.ecs_instances_sg.id]
    subnet_id                   = var.public_subnet_ids[0]
    associate_public_ip_address = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ecs-instance"
    }
  }

  user_data = base64encode(<<-EOT
      #!/bin/bash
      cat <<'EOF' >> /etc/ecs/ecs.config
      ECS_CLUSTER=${aws_ecs_cluster.adventure_cluster.name}
      ECS_LOGLEVEL=debug
      ECS_ENABLE_TASK_IAM_ROLE=true
      EOF
    EOT
  )
}

# -------------------------
# ECS Capacity Provider
# -------------------------

resource "aws_ecs_capacity_provider" "adventure_ecs_capacity_provider" {
  name = "${local.aws_ecs_service_name}-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.adventure_server_ecs_asg.arn

    managed_scaling {
      maximum_scaling_step_size = 2
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 80
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "adventure_capacity_providers" {
  cluster_name = aws_ecs_cluster.adventure_cluster.name

  capacity_providers = [aws_ecs_capacity_provider.adventure_ecs_capacity_provider.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 1
    capacity_provider = aws_ecs_capacity_provider.adventure_ecs_capacity_provider.name
  }
}

# -------------------------
# Security groups
# -------------------------
resource "aws_security_group" "lambda_sg" {
  name        = "${local.lambda_client_function_name}-sg"
  description = "Security group for Lambda in VPC"
  vpc_id      = var.vpc_id

  # --- Inbound Rules ---
  # Lambda doesn’t need inbound — it’s invoked by API Gateway
}

resource "aws_security_group" "ecs_instances_sg" {
  name        = "adventure-ecs-sg"
  description = "Security group for ECS EC2 instances"
  vpc_id      = var.vpc_id

  ingress {
    description = "Orleans silo-to-silo"
    from_port   = 11111
    to_port     = 11111
    protocol    = "tcp"
    self        = true
  }

  # --- Outbound Rules ---
  egress {
    description = "Allow all outbound traffic (for updates, ECR pulls, etc.)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    name = local.server_tag_name
  }
}

resource "aws_security_group_rule" "lambda_to_ecs" {
  type              = "egress"
  security_group_id = aws_security_group.lambda_sg.id
  source_security_group_id   = aws_security_group.ecs_instances_sg.id
  from_port        = 30000
  to_port          = 30000
  protocol         = "tcp"
}

resource "aws_security_group_rule" "ecs_to_lambda" {
  type              = "ingress"
  security_group_id = aws_security_group.ecs_instances_sg.id
  source_security_group_id = aws_security_group.lambda_sg.id
  from_port        = 30000
  to_port          = 30000
  protocol         = "tcp"
}