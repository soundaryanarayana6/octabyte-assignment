variable "project" {}
variable "vpc_id" {}
variable "public_subnets" { type = list(string) }
variable "ec2_ids" { type = list(string) }
variable "alb_sg_id" { description = "Security group for ALB" }
