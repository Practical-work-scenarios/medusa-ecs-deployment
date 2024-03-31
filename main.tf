provider "aws" {
  region = "ap-south-1" # Replace with your desired AWS region
}

resource "aws_vpc" "medusa_vpc" {
  cidr_block = "10.0.0.0/16" # Replace with your desired VPC CIDR block
}

resource "aws_subnet" "medusa_subnet_1" {
  vpc_id            = aws_vpc.medusa_vpc.id
  cidr_block        = "10.0.1.0/24" # Replace with your desired subnet CIDR block
  availability_zone = "ap-south-1a" # Replace with your desired availability zone
}

resource "aws_subnet" "medusa_subnet_2" {
  vpc_id            = aws_vpc.medusa_vpc.id
  cidr_block        = "10.0.2.0/24" # Replace with your desired subnet CIDR block
  availability_zone = "ap-south-1b" # Replace with your desired availability zone
}

resource "aws_security_group" "medusa_security_group" {
  vpc_id = aws_vpc.medusa_vpc.id

  # Define your security group rules here if needed
}

resource "aws_ecr_repository" "medusa_repository" {
  name = "medusa-backend-repo" # Replace with your desired repository name
}

resource "aws_ecs_cluster" "medusa_cluster" {
  name = "medusa-cluster" # Replace with your desired cluster name
}

resource "aws_ecs_task_definition" "medusa_task_definition" {
  family                   = "medusa-task-definition" # Replace with your desired task definition family name
  execution_role_arn       = "arn:aws:iam::030105725171:role/ecsTaskExecutionRole" # Replace with your desired execution role ARN
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      "name": "medusa-container",
      "image": "${aws_ecr_repository.medusa_repository.repository_url}:latest",
      "essential": true,
      "memory": 512,
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "medusa_service" {
  name            = "medusa-service" # Replace with your desired service name
  cluster         = aws_ecs_cluster.medusa_cluster.id
  task_definition = aws_ecs_task_definition.medusa_task_definition.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = [aws_subnet.medusa_subnet_1.id, aws_subnet.medusa_subnet_2.id] # Default subnets
    security_groups = [aws_security_group.medusa_security_group.id] # Default security group
  }
}

