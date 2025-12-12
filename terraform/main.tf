module "vpc" {
  source             = "./modules/vpc"
  env                = "dev"
  vpc_cidr           = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets    = ["10.0.101.0/24", "10.0.102.0/24"]
  availability_zones = ["us-east-1a", "us-east-1b"]
}

module "ec2" {
  source            = "./modules/ec2"
  env               = "dev"
  vpc_id            = module.vpc.vpc_id          # ← Pass VPC ID here
  public_subnet_ids = module.vpc.public_subnet_ids
  instance_type     = "t3.micro"
  ami_id            = "ami-03f9680ef0c07a3d1"
  key_name          = var.key_name
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.project}-alb-sg"
  description = "Allow HTTP traffic to ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-alb-sg"
  }
}

module "alb" {
  source = "./modules/alb"

  project        = var.project
  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnet_ids
  ec2_ids        = module.ec2.instance_ids
  alb_sg_id      = aws_security_group.alb_sg.id
}

module "rds" {
  source             = "./modules/rds"
  env                = "dev"
  project            = var.project
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  ec2_sg_id          = module.ec2.web_sg_id
  db_password        = var.db_password  
}





