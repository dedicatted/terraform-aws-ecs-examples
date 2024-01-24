variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "name" {
  type    = string
  default = "ex-test"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}


variable "container_name" {
  type    = string
  default = "ecs-sample"
}

variable "container_port" {
  type    = number
  default = 80
}

variable "tags" {
  type    = map(string)
  default = {
    Name       = "terraform"
    Example    = "terraform"
    Repository = "https://github.com/terraform-aws-modules/terraform-aws-ecs"
  }
}

variable "cidr_block" {
  type        = string
  default     = "10.10.0.0/16"
  description = "CIDR block for the VPC."
}