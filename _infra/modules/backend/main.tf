data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "ecs_node_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

data "aws_availability_zones" "available" {}

locals {
  api_gateway_name = "${var.name}-api-gateway"

  aws_ecs_service_name   = "${var.name}-ecs-service"
  aws_ecs_cluster_name   = "${var.name}-ecs-cluster"
  aws_task_def_name      = "${var.name}-server-task-definition"
  aws_ecs_keyapir        = "${var.name}-ecs-keypair" // Created manually
  aws_ecs_container_name = "${var.name}-server-container"

  account_id = data.aws_caller_identity.current.account_id

  server_tag_name = "${var.name}-server"

  cluster_id = "ecs-orleans-cluster"
  service_id = "ecs-orleans-service"
}

###############
#  ECS Cluster
###############

resource "aws_ecs_cluster" "adventure_cluster" {
  name = local.aws_ecs_cluster_name
}

resource "aws_security_group" "ecs" {
  name   = "${var.name}-ecs-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port   = 11111
    to_port     = 11111
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress { 
    from_port = 0 
    to_port = 0 
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

###############
# ECS Service API
###############

resource "aws_cloudwatch_log_group" "api" {
  name = "/ecs/${var.name}-api"
}

resource "aws_lb" "client_alb" {
  name               = "${var.name}-client-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_target_group" "client_alb_tg" {
  name     = "${var.name}-client-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check { path = "/health" }
}

resource "aws_security_group" "alb" {
  name   = "${var.name}-alb-sg"
  vpc_id = var.vpc_id

  ingress { 
    from_port = 80 
    to_port = 80 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
  }
  egress  { 
    from_port = 0  
    to_port = 0  
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

resource "aws_ecs_service" "client" {
  name            = "${var.name}-client-service"
  cluster         = aws_ecs_cluster.adventure_cluster.id
  task_definition = aws_ecs_task_definition.adventure_client_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.ecs.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.client_alb_tg.arn
    container_name   = "api"
    container_port   = 80
  }
}

resource "aws_ecs_task_definition" "adventure_client_task_definition" {
  family             = local.aws_task_def_name
  network_mode       = "awsvpc"
  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_client_task_role.arn
  
  requires_compatibilities = ["FARGATE"]
  depends_on               = [aws_cloudwatch_log_group.api]

  container_definitions = jsonencode([{
    name      = "${local.aws_ecs_container_name}-client"
    image     = var.default_client_image_url
    essential = true
    portMappings = [{ containerPort = 80, hostPort = 80 }]
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
      { "name" : "ORLEANS_CLUSTER_ID", "value" : local.cluster_id },
      { "name" : "ORLEANS_SERVICE_ID", "value" : local.service_id },
      { "name" : "CLUSTER_TABLE_NAME", "value": var.dynamodb_cluster_table_name}
    ]
  }])
}

###############
# ECS Service Cluster
###############

# -------------------------
# ECS Cluster
# -------------------------

resource "aws_cloudwatch_log_group" "ecs_app" {
  name              = "/ecs/${var.name}-cluster"
  retention_in_days = 3
}

resource "aws_ecs_service" "adventure-server" {
  name            = local.aws_ecs_service_name
  desired_count   = 1
  task_definition = aws_ecs_task_definition.adventure_server_task_definition.arn
  cluster         = aws_ecs_cluster.adventure_cluster.id
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.ecs.id]
  }

  tags = {
    name = local.server_tag_name
  }
}

resource "aws_ecs_task_definition" "adventure_server_task_definition" {
  family             = local.aws_task_def_name
  network_mode       = "awsvpc"
  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.adventure_ecs_task_role.arn
  
  requires_compatibilities = ["FARGATE"]
  depends_on               = [aws_cloudwatch_log_group.ecs_app]

  container_definitions = jsonencode([{
    name      = local.aws_ecs_container_name
    image     = var.default_server_image_url
    essential = true
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
      { "name" : "ORLEANS_CLUSTER_ID", "value" : local.cluster_id },
      { "name" : "ORLEANS_SERVICE_ID", "value" : local.service_id },
      { "name" : "ORLEANS_SILO_PORT", "value": "11111" },
      { "name" : "ORLEANS_GATEWAY_PORT", "value": "30000" },
      { "name" : "GRAIN_TABLE_NAME", "value" : var.dynamodb_grain_table_name },
      { "name" : "CLUSTER_TABLE_NAME", "value": var.dynamodb_cluster_table_name}
    ]
  }])
}

########
# IAM Roles and Policies
########
// run task
resource "aws_iam_role" "ecs_execution_role" {
  name               = "${var.name}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals { 
      type = "Service" 
      identifiers = ["ecs-tasks.amazonaws.com"] 
    }
  }
}

// run server task role
resource "aws_iam_role" "adventure_ecs_task_role" {
  name               = "${var.name}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "dynamo_clientcluster_policy_attach" {
  role       = aws_iam_role.adventure_ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_orleans_dynamodb_cluster_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_exec_attach_server" {
  role       = aws_iam_role.adventure_ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "dynamo_server_grain_policyattach" {
  role       = aws_iam_role.adventure_ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_orleans_dynamodb_grain_policy.arn
}

// run client task role
resource "aws_iam_role" "ecs_client_task_role" {
  name               = "${var.name}-ecs-client-taskrole"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_exec_attach_client" {
  role       = aws_iam_role.ecs_client_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "dynamo_server_cluster_policy_attach" {
  role       = aws_iam_role.ecs_client_task_role.name
  policy_arn = aws_iam_policy.ecs_orleans_dynamodb_cluster_policy.arn
}

## dynamo policies

resource "aws_iam_policy" "ecs_orleans_dynamodb_cluster_policy" {
  name        = "ecs-orleans-dynamodb-cluster-access"
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
          var.dynamodb_cluster_table_arn
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "ecs_orleans_dynamodb_grain_policy" {
  name        = "ecs-orleans-dynamodb-grain-access"
  description = "Allow ECS (Orleans) to use DynamoDB for grains"

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
          var.dynamodb_table_grain_arn
        ]
      }
    ]
  })
}
