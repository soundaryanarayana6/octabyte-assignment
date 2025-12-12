variable "env" {
  description = "Environment name"
  default     = "dev"
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.micro"  # Free Tier eligible
}

variable "ami_id" {
  description = "AMI ID for EC2"
  default     = "aami-03f9680ef0c07a3d1"  # Amazon Linux 2 in us-east-1
}

variable "key_name" {
  description = "Key pair name for SSH access"
  default     = "my-key"  # Create a key in AWS if you want SSH access
  type = string
}

variable "vpc_id" {
  description = "VPC ID where EC2 instances will be launched"
  type        = string
}
