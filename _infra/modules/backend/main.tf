
data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "ecs_node_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

data "aws_availability_zones" "available" {}

locals {
    lambda_role_name            = "${var.name}-lambda-role"
    lambda_client_function_name = "${var.name}-client"

    api_gateway_name = "${var.name}-api-gateway"

    aws_ecs_service_name = "${var.name}-ecs-service"
    aws_ecs_cluster_name = "${var.name}-ecs-cluster"
    aws_task_def_name    = "${var.name}-server-task-definition"
    aws_ecs_keyapir      = "${var.name}-ecs-keypair" // Created manually

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

resource "aws_internet_gateway" "internet_gateway" {
 vpc_id = var.vpc_id
 tags = {
   Name = "${local.aws_ecs_service_name}-ig"
 }
}

# NAT Gateway setup
resource "aws_eip" "nat" {
  tags   = { Name = "ecs-nat-eip" }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.public_subnet_ids[0]
  tags          = { Name = "ecs-nat" }
}

resource "aws_route_table" "public_route_table" {
 vpc_id = var.vpc_id
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.internet_gateway.id
 }
 tags = {
   Name = "${local.aws_ecs_service_name}-rt"
 }
}

resource "aws_route_table_association" "route_table_association" {
  count          = 2
  subnet_id      = var.public_subnet_ids[count.index]
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "private" {
  vpc_id = var.vpc_id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "ecs-private-rt" }
}

resource "aws_route_table_association" "private_assoc" {
  count          = 2
  subnet_id      = var.private_subnet_ids[count.index]
  route_table_id = aws_route_table.private.id
}

################
# Security Group
################
resource "aws_security_group" "adventure_server_security_group" {
 name   = "${local.aws_ecs_service_name}-sg"
 vpc_id = var.vpc_id

 ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
   Name = "${local.aws_ecs_service_name}-private-sg"
 }
}

###############
# IAM Role
################

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

# -------------------------
# ECS Cluster
# -------------------------

resource "aws_ecs_cluster" "adventure_cluster" {
 name = local.aws_ecs_cluster_name
}

# -------------------------
# Launch Template
# -------------------------

resource "aws_launch_template" "adventure_server_ecs_lt" {
 name_prefix   = "${local.aws_ecs_service_name}-tmpl"
 image_id      = data.aws_ssm_parameter.ecs_node_ami.value
 instance_type = "t3.micro"
 key_name      = local.aws_ecs_keyapir

 vpc_security_group_ids = [aws_security_group.adventure_server_security_group.id]
 
 iam_instance_profile { 
    name = aws_iam_instance_profile.adventure_ecs_node.name 
 }

 tag_specifications {
   resource_type = "instance"
   tags = {
     Name = "ecs-instance"
   }
 }

 user_data = base64encode(<<-EOF
      #!/bin/bash
      echo ECS_CLUSTER=${aws_ecs_cluster.adventure_cluster.name} >> /etc/ecs/ecs.config;

      # Install CloudWatch Agent
        yum install -y amazon-cloudwatch-agent
        cat <<CWAGENT > /opt/aws/amazon-cloudwatch-agent/bin/config.json
        {
          "metrics": {
            "append_dimensions": {
              "AutoScalingGroupName": "$${aws:AutoScalingGroupName}",
              "InstanceId": "$${aws:InstanceId}"
            },
            "metrics_collected": {
              "mem": {
                "measurement": ["mem_used_percent"]
              },
              "disk": {
                "measurement": ["disk_used_percent"],
                "resources": ["*"]
              }
            }
          }
          CWAGENT
    systemctl enable amazon-cloudwatch-agent
    systemctl start amazon-cloudwatch-agent
    EOF
      )
}

# -------------------------
# Auto Scaling Group
# -------------------------

resource "aws_autoscaling_group" "adventure_server_ecs_asg" {
 name                      = "${local.aws_ecs_service_name}-asg"
 vpc_zone_identifier       = var.private_subnet_ids
 desired_capacity          = 2
 max_size                  = 2
 min_size                  = 1
 
 lifecycle {
    create_before_destroy = true
  }

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

# ------------------------------------------------
# ECS TASK DEFINITION
# ------------------------------------------------

resource "aws_ecs_task_definition" "adventure_server_task_definition" {
  family             = local.aws_task_def_name
  cpu                = 256
  memory             = "512"
  network_mode       = "awsvpc"
  execution_role_arn = "arn:aws:iam::${local.account_id}:role/ecsTaskExecutionRole"

  runtime_platform {
   operating_system_family = "LINUX"
   cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([{
    name      = "adventure-server-container"
    image     = var.default_server_image_url
    essential = true
    memory    = 512
    portMappings = [
      { "containerPort": 80, "hostPort": 80 }
    ],
    environment = [
      { name  = "ENVIRONMENT", value = "Production" },
      { name  = "ASPNETCORE_ENVIRONMENT", value = "Production" },
      { "name": "ORLEANS_CLUSTER_ID", "value": "ecs-orleans-cluster" },
      { "name": "ORLEANS_SERVICE_ID", "value": "ecs-orleans-service" },
      { "name": "AWS_REGION", "value": "us-east-1" }
    ]
  }])
}

resource "aws_ecs_service" "adventure-server" {
  name            = local.aws_ecs_service_name
  desired_count   = 1
  task_definition = aws_ecs_task_definition.adventure_server_task_definition.arn
  cluster         = aws_ecs_cluster.adventure_cluster.id
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = aws_lb_target_group.adventure_ecs_tg.arn
    container_name   = "orleans-silo"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.adventure_ecs_listener]

  tags = {
   name = local.server_tag_name
 }
}

# ------------------------------------------------
# Load balancer 
# ------------------------------------------------

resource "aws_security_group" "alb" {
  vpc_id = var.vpc_id
  name   = "alb-sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "alb-sg" }
}

resource "aws_lb" "adventure_ecs_lb" {
  name               = "adventure-ecs-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.adventure_server_security_group.id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "adventure_ecs_tg" {
  name     = "adventure-ecs-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "instance"
}

resource "aws_lb_listener" "adventure_ecs_listener" {
  load_balancer_arn = aws_lb.adventure_ecs_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.adventure_ecs_tg.arn
  }
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
          "dynamodb:DescribeTable",
          "dynamodb:CreateTable"
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




