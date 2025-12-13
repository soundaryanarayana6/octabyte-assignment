terraform {
  backend "s3" {
    bucket         = "octabyte-tf-state-20251213152857404500000001"
    region         = "us-east-1"
    dynamodb_table = "octabyte-tf-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "OctabyteAssignment"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
