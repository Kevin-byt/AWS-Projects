# create ecs cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

# create cloudwatch log group
resource "aws_cloudwatch_log_group" "log_group" {
  name = "/ecs/${var.project_name}-${var.environment}-td"

  lifecycle {
    create_before_destroy = true
  }
}

# create task definition for service 1
resource "aws_ecs_task_definition" "ecs_task_definition_service1" {
  family                   = "${var.project_name}-${var.environment}-service1-td"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.architecture
  }

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-${var.environment}-service1-container"
      image     = "${var.ecr_registry}/${var.image_name1}:${var.image_tag1 != "" ? var.image_tag1 : var.image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]

      environment = [
        {
          name = "DB_USER"
          value = var.db_user
        },
        {
          name = "DB_PASSWORD"
          value = var.db_password
        },
        {
          name = "DB_NAME"
          value = var.db_name
        },
        {
          name = "DB_HOST"
          value = aws_db_instance.database_instance.address
        },
        {
          name = "DB_PORT"
          value = tostring(var.db_port)
        }
      ]

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = "${aws_cloudwatch_log_group.log_group.name}",
          "awslogs-region"        = "${var.region}",
          "awslogs-stream-prefix" = "service1"
        }
      }
    }
  ])
}

# create task definition for service 2
resource "aws_ecs_task_definition" "ecs_task_definition_service2" {
  family                   = "${var.project_name}-${var.environment}-service2-td"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.architecture
  }

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-${var.environment}-service2-container"
      image     = "${var.ecr_registry}/${var.image_name2}:${var.image_tag2 != "" ? var.image_tag2 : var.image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]

      environment = [
        {
          name = "DB_USER"
          value = var.db_user
        },
        {
          name = "DB_PASSWORD"
          value = var.db_password
        },
        {
          name = "DB_NAME"
          value = var.db_name
        },
        {
          name = "DB_HOST"
          value = aws_db_instance.database_instance.address
        },
        {
          name = "DB_PORT"
          value = tostring(var.db_port)
        }
      ]

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = "${aws_cloudwatch_log_group.log_group.name}",
          "awslogs-region"        = "${var.region}",
          "awslogs-stream-prefix" = "service2"
        }
      }
    }
  ])
}

# create ecs service 1
resource "aws_ecs_service" "ecs_service1" {
  name                               = "${var.project_name}-${var.environment}-service1"
  launch_type                        = "FARGATE"
  cluster                            = aws_ecs_cluster.ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.ecs_task_definition_service1.arn
  platform_version                   = "LATEST"
  desired_count                      = 1
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  enable_ecs_managed_tags = false
  propagate_tags          = "SERVICE"

  network_configuration {
    subnets          = [aws_subnet.private_app_subnet_az1.id, aws_subnet.private_app_subnet_az2.id]
    security_groups  = [aws_security_group.app_server_security_group.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.reader_target_group.arn
    container_name   = "${var.project_name}-${var.environment}-service1-container"
    container_port   = 8000
  }
}

# create ecs service 2
resource "aws_ecs_service" "ecs_service2" {
  name                               = "${var.project_name}-${var.environment}-service2"
  launch_type                        = "FARGATE"
  cluster                            = aws_ecs_cluster.ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.ecs_task_definition_service2.arn
  platform_version                   = "LATEST"
  desired_count                      = 1
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  enable_ecs_managed_tags = false
  propagate_tags          = "SERVICE"

  network_configuration {
    subnets          = [aws_subnet.private_app_subnet_az1.id, aws_subnet.private_app_subnet_az2.id]
    security_groups  = [aws_security_group.app_server_security_group.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.writer_target_group.arn
    container_name   = "${var.project_name}-${var.environment}-service2-container"
    container_port   = 8000
  }
}
