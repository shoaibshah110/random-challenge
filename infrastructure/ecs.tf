# Resources

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ECSTaskExecutionRolePolicy"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# ECS Task Execution Role Policy
resource "aws_iam_policy" "ecsTaskExecutionRolePolicy" {
  name        = "ecsTaskExecutionRolePolicy"
  description = "Policy for ECS Task Execution Role"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "ecr:GetAuthorizationToken",
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action   = "ecr:BatchCheckLayerAvailability",
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action   = "ecr:GetDownloadUrlForLayer",
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action   = "ecr:BatchGetImage",
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action   = "logs:CreateLogStream",
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action   = "logs:PutLogEvents",
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

# ECS Task Execution Role Policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecsTaskExecutionRolePolicy.arn
}

# ECR Repository
resource "aws_ecr_repository" "ecrRepository" {
  name = "preprod-images"
}

# AWS ECS Cluster
resource "aws_ecs_cluster" "ecsCluster" {
  name = "preprod"
}

# Amazon ECS capacity provider - To manage the scaling of infrastructure for tasks in your clusters
resource "aws_ecs_capacity_provider" "CapacityProvider" {
  name = "capacity-provider"
  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecsAutoScalingGroup.arn
    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 3
    }
  }
}

# Amazon ECS capacity provider to cluster
resource "aws_ecs_cluster_capacity_providers" "ecsCapacityProvider" {
  cluster_name       = aws_ecs_cluster.ecsCluster.name
  capacity_providers = [aws_ecs_capacity_provider.CapacityProvider.name]
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.CapacityProvider.name
    base              = 1
    weight            = 100
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "ecsTaskDefinition" {
  family             = "laravel-service-task"
  network_mode       = "awsvpc"
  cpu                = "256"
  memory             = "512"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "laravel-service-task"
      image     = "public.ecr.aws/f9n5f1l7/dgs:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
}

# ECS Service based on Task Definition
resource "aws_ecs_service" "ecsService" {
  name            = "laravel-service"
  cluster         = aws_ecs_cluster.ecsCluster.id
  task_definition = aws_ecs_task_definition.ecsTaskDefinition.arn
  desired_count   = 2
  network_configuration {
    subnets         = [aws_subnet.preprodSubnet1.id, aws_subnet.preprodSubnet2.id]
    security_groups = [aws_security_group.ecsSecurityGroup.id]
  }
  force_new_deployment = true
  placement_constraints {
    type = "distinctInstance"
  }
  triggers = {
    redeployment = timestamp()
  }
  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.CapacityProvider.name
    weight            = 100
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.applicationLoadBalancerTargetGroup.arn
    container_name   = "laravel-service-task"
    container_port   = 80
  }
  depends_on = [aws_autoscaling_group.ecsAutoScalingGroup]
}