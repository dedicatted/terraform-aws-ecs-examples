variable "ecs_key_description" {
  default     = "example"
  description = "Description for the ECS Key"
}

variable "ecs_key_deletion_window_in_days" {
  default     = 7
  description = "Deletion window in days for the ECS Key"
}

variable "ecs_log_group_name" {
  default     = "example"
  description = "Name for the ECS CloudWatch Log Group"
}

variable "ecs_cluster_name" {
  default     = "example"
  description = "Name for the ECS Cluster"
}

variable "ecs_service_name" {
  default     = "example"
  description = "Name for the ECS Service"
}

variable "ecs_desired_count" {
  default     = 3
  description = "Desired count for the ECS Service"
}

variable "ecs_container_name" {
  default     = ""
  description = "Name for the ECS container"
}

variable "ecs_container_port" {
  default     = 0
  description = "Port for the ECS container"
}
variable "ecs_launch_type" {
  default     = "EC2"
  description = "Launch type for the ECS service (EC2, FARGATE, EXTERNAL)"
}

variable "fargate_capacity_providers" {
  default     = ["FARGATE"]
  description = "List of Fargate capacity providers"
}

variable "fargate_capacity_base" {
  default     = 1
  description = "Base value for Fargate capacity provider strategy"
}

variable "fargate_capacity_weight" {
  default     = 100
  description = "Weight value for Fargate capacity provider strategy"
}
variable "create_cloudwatch_log_group" {
  default     = false
  description = "Whether to create the ECS CloudWatch Log Group"
}