# Terraform ECS using official modules and resources

## Example of creating ECS Fargate

```
data "aws_availability_zones" "available" {
  state = "available"
}
module "vpc" {
  source             = "github.com/terraform-aws-modules/terraform-aws-vpc"
  name               = var.vpc_name
  cidr               = var.cidr_block
  azs                = slice(data.aws_availability_zones.available.names, 0, 1)
  public_subnets     = [cidrsubnet(var.cidr_block, 8, 3), cidrsubnet(var.cidr_block, 8, 4), cidrsubnet(var.cidr_block, 8, 5)]
  private_subnets    = [cidrsubnet(var.cidr_block, 8, 0), cidrsubnet(var.cidr_block, 8, 1), cidrsubnet(var.cidr_block, 8, 2)]
  enable_nat_gateway = true
  single_nat_gateway = true
}
module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "ecs-integrated"

  services = {
    ecsdemo-frontend = {
      cpu    = 1024
      memory = 4096

      # Container definition(s)
      container_definitions = {

        ecs-sample = {
          cpu       = 512
          memory    = 1024
          essential = true
          image     = "public.ecr.aws/aws-containers/ecsdemo-frontend:776fd50"
          port_mappings = [
            {
              name          = "ecs-sample"
              containerPort = 80
              protocol      = "tcp"
            }
          ]
        }
      }


      subnet_ids = module.vpc.public_subnets 
    }
  }

  tags = {
    Environment = "Development"
    Project     = "Example"
  }
}
```

## Example to use Fargate Spot

```
data "aws_availability_zones" "available" {
  state = "available"
}
module "vpc" {
  source             = "github.com/terraform-aws-modules/terraform-aws-vpc"
  name               = var.vpc_name
  cidr               = var.cidr_block
  azs                = slice(data.aws_availability_zones.available.names, 0, 1)
  public_subnets     = [cidrsubnet(var.cidr_block, 8, 3), cidrsubnet(var.cidr_block, 8, 4), cidrsubnet(var.cidr_block, 8, 5)]
  private_subnets    = [cidrsubnet(var.cidr_block, 8, 0), cidrsubnet(var.cidr_block, 8, 1), cidrsubnet(var.cidr_block, 8, 2)]
  enable_nat_gateway = true
  single_nat_gateway = true
}
module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "ecs-integrated"
  fargate_capacity_providers = {
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

  services = {
    ecsdemo-frontend = {
      cpu    = 1024
      memory = 4096

      # Container definition(s)
      container_definitions = {

        ecs-sample = {
          cpu       = 512
          memory    = 1024
          essential = true
          image     = "public.ecr.aws/aws-containers/ecsdemo-frontend:776fd50"
          port_mappings = [
            {
              name          = "ecs-sample"
              containerPort = 80
              protocol      = "tcp"
            }
          ]
        }
      }


      subnet_ids = module.vpc.public_subnets
    }
  }

  tags = {
    Environment = "Development"
    Project     = "Example"
  }
}
```

## Example to use EC2 type

```
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

```

## Example to use EC2 with autoscale

```
data "aws_availability_zones" "available" {
  state = "available"
}

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws"

  cluster_name = var.name

  # Capacity provider - autoscaling groups
  default_capacity_provider_use_fargate = false
  autoscaling_capacity_providers = {
    # On-demand instances
    ex_1 = {
      auto_scaling_group_arn         = module.autoscaling["ex_1"].autoscaling_group_arn
      managed_termination_protection = "ENABLED"

      managed_scaling = {
        maximum_scaling_step_size = 5
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 60
      }

      default_capacity_provider_strategy = {
        weight = 60
        base   = 20
      }
    }
    # Spot instances
    ex_2 = {
      auto_scaling_group_arn         = module.autoscaling["ex_2"].autoscaling_group_arn
      managed_termination_protection = "ENABLED"

      managed_scaling = {
        maximum_scaling_step_size = 15
        minimum_scaling_step_size = 5
        status                    = "ENABLED"
        target_capacity           = 90
      }

      default_capacity_provider_strategy = {
        weight = 40
      }
    }
  }

  tags = var.tags
}


module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 6.5"

  for_each = {
    # On-demand instances
    ex_1 = {
      instance_type              = "t3.large"
      use_mixed_instances_policy = false
      mixed_instances_policy     = {}
      user_data                  = <<-EOT
        #!/bin/bash

        cat <<'EOF' >> /etc/ecs/ecs.config
        ECS_CLUSTER=${var.name}
        ECS_LOGLEVEL=debug
        ECS_CONTAINER_INSTANCE_TAGS=${jsonencode(var.tags)}
        ECS_ENABLE_TASK_IAM_ROLE=true
        EOF
      EOT
    }
    # Spot instances
    ex_2 = {
      instance_type              = "t3.medium"
      use_mixed_instances_policy = true
      mixed_instances_policy = {
        instances_distribution = {
          on_demand_base_capacity                  = 0
          on_demand_percentage_above_base_capacity = 0
          spot_allocation_strategy                 = "price-capacity-optimized"
        }

        override = [
          {
            instance_type     = "m4.large"
            weighted_capacity = "2"
          },
          {
            instance_type     = "t3.large"
            weighted_capacity = "1"
          },
        ]
      }
      user_data = <<-EOT
        #!/bin/bash

        cat <<'EOF' >> /etc/ecs/ecs.config
        ECS_CLUSTER=${var.name}
        ECS_LOGLEVEL=debug
        ECS_CONTAINER_INSTANCE_TAGS=${jsonencode(var.tags)}
        ECS_ENABLE_TASK_IAM_ROLE=true
        ECS_ENABLE_SPOT_INSTANCE_DRAINING=true
        EOF
      EOT
    }
  }

  name = "${var.name}-${each.key}"

  image_id      = "public.ecr.aws/aws-containers/ecsdemo-frontend:776fd50"
  instance_type = each.value.instance_type

  security_groups                 = [module.autoscaling_sg.security_group_id]
  user_data                       = base64encode(each.value.user_data)
  ignore_desired_capacity_changes = true

  create_iam_instance_profile = true
  iam_role_name               = var.name
  iam_role_description        = "ECS role for ${var.name}"
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  vpc_zone_identifier = module.vpc.private_subnets
  health_check_type   = "EC2"
  min_size            = 1
  max_size            = 5
  desired_capacity    = 2

  autoscaling_group_tags = {
    AmazonECSManaged = true
  }

  protect_from_scale_in = true

  # Spot instances
  use_mixed_instances_policy = each.value.use_mixed_instances_policy
  mixed_instances_policy     = each.value.mixed_instances_policy

  tags = var.tags
}

module "autoscaling_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = var.name
  description = "Autoscaling group security group"
  vpc_id      = module.vpc.vpc_id

  egress_rules = ["all-all"]

  tags = var.tags
}

module "vpc" {
  source             = "github.com/terraform-aws-modules/terraform-aws-vpc"
  name               = "vpc"
  cidr               = var.cidr_block
  azs                = slice(data.aws_availability_zones.available.names, 0, 1)
  public_subnets     = [cidrsubnet(var.cidr_block, 8, 3), cidrsubnet(var.cidr_block, 8, 4), cidrsubnet(var.cidr_block, 8, 5)]
  private_subnets    = [cidrsubnet(var.cidr_block, 8, 0), cidrsubnet(var.cidr_block, 8, 1), cidrsubnet(var.cidr_block, 8, 2)]
  enable_nat_gateway = true
  single_nat_gateway = true
}

```