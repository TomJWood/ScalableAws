//Create ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs_cluster_01"
}

//Associate auto scaling group with ECS capacity provider
resource "aws_ecs_capacity_provider" "aws_ecs_capacity_provider" {
  name = "ecs_capacity_provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_auto_scaling_group.arn

    //Set scaling rules
    managed_scaling {
      maximum_scaling_step_size = 20
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 3
    }
  }
}

//Bind auto scaling group capacity provider to ECS
resource "aws_ecs_cluster_capacity_providers" "ecs_capacity_provider_bind" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name

  capacity_providers = [aws_ecs_capacity_provider.aws_ecs_capacity_provider.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.aws_ecs_capacity_provider.name
  }
}

//Create Task Definition for our ECS
resource "aws_ecs_task_definition" "aws_ecs_task_definition" {
  family             = "ecs_task_definition_01"
  network_mode       = "awsvpc" //Use VPC networking defined in vpc.tf
  execution_role_arn = "arn:aws:iam::929389731404:role/ecsTaskExecutionRole"
  cpu                = 256
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  //Resource requirements of the container to be run in the task
  container_definitions = jsonencode([
    {
      name      = "dockergs"
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

//Create the ECS service to run on the cluster
resource "aws_ecs_service" "ecs_service" {
  name            = "ecs_service_01"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.aws_ecs_task_definition.arn
  desired_count   = 2 //two instances of our container image on the cluster

  //Specify subnets and security group
  network_configuration {
    subnets         = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
    security_groups = [aws_security_group.security_group.id]
  }

  force_new_deployment = true
  placement_constraints {
    type = "distinctInstance"
  }



  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.aws_ecs_capacity_provider.name
    weight            = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "dockergs"
    container_port   = 80
  }

  depends_on = [aws_autoscaling_group.ecs_auto_scaling_group]

}