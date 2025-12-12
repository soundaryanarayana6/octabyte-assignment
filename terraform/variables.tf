variable "project" {
  default = "myapp"
}

variable "db_password" {
  description = "Database password for RDS"
  type        = string
  sensitive   = true
}

variable "key_name" {
  description = "Name of the AWS key pair to use for EC2 instances"
  type        = string
}