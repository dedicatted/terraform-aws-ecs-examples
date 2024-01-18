resource "aws_kms_key" "ecs" {
  count = var.create_cloudwatch_log_group ? 1 : 0

  description             = var.ecs_key_description
  deletion_window_in_days = var.ecs_key_deletion_window_in_days
}

resource "aws_cloudwatch_log_group" "ecs" {
  count = var.create_cloudwatch_log_group ? 1 : 0
  name  = var.ecs_log_group_name
}

resource "aws_ecs_cluster" "cluster" {
  name = var.ecs_cluster_name

  configuration {
    execute_command_configuration {
      kms_key_id = var.create_cloudwatch_log_group ? aws_kms_key.ecs[0].arn : null
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.ecs[0].name : null
      }
    }
  }
}


resource "aws_ecs_service" "service" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.service.arn
  desired_count   = var.ecs_desired_count
  #iam_role        = aws_iam_role.foo.arn

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  dynamic "load_balancer" {
    for_each = var.ecs_container_name != "" && var.ecs_container_port != 0 ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.foo.arn
      container_name   = var.ecs_container_name
      container_port   = var.ecs_container_port
    }
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [${join(", ", data.aws_availability_zones.available.names)}]"
  }

  launch_type = var.ecs_launch_type

}

resource "aws_ecs_cluster_capacity_providers" "ecs" {
  count = length(var.fargate_capacity_providers) > 0 ? 1 : 0

  cluster_name = var.ecs_cluster_name

  capacity_providers = var.fargate_capacity_providers

  default_capacity_provider_strategy {
    base              = var.fargate_capacity_base
    weight            = var.fargate_capacity_weight
    capacity_provider = var.fargate_capacity_providers[0]
  }
}
