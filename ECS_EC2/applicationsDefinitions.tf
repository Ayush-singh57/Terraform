# Container and service
resource "aws_ecs_task_definition" "app" {
  family                   = "my-web-app"
  network_mode             = "bridge" 
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "my-react-app"
      image     ="835637956758.dkr.ecr.ap-south-1.amazonaws.com/my-repo:latest" # use Nginx \
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 0 
          protocol      = "tcp"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "app_service" {
  name            = "ecs-app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2  

 capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2_capacity.name
    weight            = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "my-react-app"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.ecs_listener]
}   