variable "vpc_name" {
  type        = string
  default     = "eks-vpc"
  description = "Name for the VPC."
}

variable "cidr_block" {
  type        = string
  default     = "10.10.0.0/16"
  description = "CIDR block for the VPC."
}
variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region to deploy."
}