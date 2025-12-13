module "vpc" {
  source             = "./modules/vpc"
  env                = var.environment
  vpc_cidr           = var.vpc_cidr
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones
}

module "ec2" {
  source            = "./modules/ec2"
  env               = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  instance_type     = var.instance_type
  ami_id            = var.ami_id
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
  env                = var.environment
  project            = var.project
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  ec2_sg_id          = module.ec2.web_sg_id
  db_password        = var.db_password  
}





