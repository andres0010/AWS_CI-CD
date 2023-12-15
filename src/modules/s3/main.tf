provider "aws" {
  region = "us-west-1"
}

resource "aws_vpc" "harlen-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "harlen-vpc"
  }
}


resource "aws_subnet" "harlen-subnet" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.harlen-vpc.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "harlen Subnet ${count.index + 1}"
  }
}

resource "aws_internet_gateway" "harlen-igw" {
  vpc_id = aws_vpc.harlen-vpc.id

  tags = {
    Name = "harlen-igw"
  }
}

resource "aws_route_table" "harlen-rt" {
  vpc_id = aws_vpc.harlen-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.harlen-igw.id
  }

  tags = {
    Name = "harlen-rt"
  }
}

resource "aws_route_table_association" "public_subnet_asso" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.harlen-subnet[*].id, count.index)
  route_table_id = aws_route_table.harlen-rt.id
}

resource "aws_security_group" "harlen-sg" {
  name   = "harlen-sg"
  vpc_id = aws_vpc.harlen-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    self        = "false"
    cidr_blocks = ["0.0.0.0/0"]
    description = "any"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "harlen-sg"
  }
}

resource "aws_ecs_cluster" "harlen-ecs-cluster" {
  name = "harlen-ecs-cluster"
}

resource "aws_ecs_cluster_capacity_providers" "harlen-cluster-provider" {
  cluster_name = aws_ecs_cluster.harlen-ecs-cluster.name

  capacity_providers = ["FARGATE_SPOT", "FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
  }
}

resource "aws_ecs_task_definition" "harlen-task" {
  family                   = "harlen"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE", "EC2"]
  cpu                      = 256
  memory                   = 512

  container_definitions = jsonencode([
    {
      name : "nginx",
      image : "nginx:latest",
      essential : true,
      portMappings : [
        {
          containerPort : 80,
          hostPort : 80,
        },
      ],
    },
  ])

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_lb" "harlen-lb" {
  name            = "harlen-lb"
  subnets         = aws_subnet.harlen-subnet.*.id
  security_groups = [aws_security_group.harlen-sg.id]
}

resource "aws_lb_target_group" "harlen-tg" {
  name        = "harlen-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.harlen-vpc.id
  target_type = "ip"
}

resource "aws_lb_listener" "harlen-listener" {
  load_balancer_arn = aws_lb.harlen-lb.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.harlen-tg.id
    type             = "forward"
  }
}

resource "aws_ecs_service" "harlen-service" {
  name             = "harlen-service"
  cluster          = aws_ecs_cluster.harlen-ecs-cluster.id
  task_definition  = aws_ecs_task_definition.harlen-task.arn
  desired_count    = 2
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  load_balancer {
    target_group_arn = aws_lb_target_group.harlen-tg.arn
    container_name   = "nginx"
    container_port   = 80
  }

  network_configuration {
    assign_public_ip = true
    subnets          = aws_subnet.harlen-subnet.*.id
  }

}

resource "aws_s3_bucket" "harlen-buck…
