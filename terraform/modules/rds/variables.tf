variable "env" {}
variable "project" {}
variable "vpc_id" {}
variable "private_subnet_ids" {
  type = list(string)
}
variable "ec2_sg_id" {
  description = "Security group ID of EC2 instances to allow access to RDS"
  type        = string
}
variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}