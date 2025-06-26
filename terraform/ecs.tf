# ECSクラスター
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# CloudWatch Log Group - フロントエンド
resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.project_name}-frontend"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-frontend-logs"
  }
}

# CloudWatch Log Group - バックエンド
resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project_name}-backend"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-backend-logs"
  }
}

# ECSタスク定義 - フロントエンド
resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.project_name}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "frontend"
      image = "${aws_ecr_repository.frontend.repository_url}:${var.frontend_image_tag}"

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.frontend.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }

      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "VITE_API_URL"
          value = "https://${aws_lb.main.dns_name}"
        }
      ]
    }
  ])

  tags = {
    Name = "${var.project_name}-frontend-task"
  }
}

# ECSタスク定義 - バックエンド
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "backend"
      image = "${aws_ecr_repository.backend.repository_url}:${var.backend_image_tag}"

      portMappings = [
        {
          containerPort = 3001
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.backend.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:3001/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 120
      }

      environment = [
        {
          name  = "RAILS_ENV"
          value = "production"
        },
        {
          name  = "DB_HOST"
          value = aws_db_proxy.main.endpoint
        },
        {
          name  = "DB_USERNAME"
          value = var.db_username
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        },
        {
          name  = "DB_PORT"
          value = "5432"
        }
      ]

      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = aws_secretsmanager_secret.db_password.arn
        },
        {
          name      = "RAILS_MASTER_KEY"
          valueFrom = aws_secretsmanager_secret.rails_master_key.arn
        },
        {
          name      = "JWT_SECRET_KEY"
          valueFrom = aws_secretsmanager_secret.jwt_secret_key.arn
        }
      ]

      essential = true
      startTimeout = 600
      stopTimeout = 30
    }
  ])

  tags = {
    Name = "${var.project_name}-backend-task"
  }
}

# ECSサービス - フロントエンド
resource "aws_ecs_service" "frontend" {
  name            = "${var.project_name}-frontend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs.id]
    subnets          = aws_subnet.private[*].id
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.https_frontend]

  tags = {
    Name = "${var.project_name}-frontend-service"
  }
}

# ECSサービス - バックエンド
resource "aws_ecs_service" "backend" {
  name            = "${var.project_name}-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs.id]
    subnets          = aws_subnet.private[*].id
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 3001
  }

  health_check_grace_period_seconds = 60

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 50

  depends_on = [aws_lb_listener.https_frontend]

  tags = {
    Name = "${var.project_name}-backend-service"
  }
}
