data "aws_availability_zones" "available" {}

resource "aws_ecs_cluster" "cluster" {
  name = "testECS"
}

resource "aws_ecs_service" "service" {
  name            = "testECS"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.service.arn
  desired_count   = "3"
  #iam_role        = aws_iam_role.foo.arn

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  dynamic "load_balancer" {
    for_each = var.ecs_container_name != "" && var.ecs_container_port != 0 ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.foo.arn
      container_name   = "testECS"
      container_port   = "80"
    }
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [${join(", ", data.aws_availability_zones.available.names)}]"
  }

  launch_type =  "EC2"

}
