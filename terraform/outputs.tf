#Expose RDS endpoint from module
output "rds_endpoint" {
  value = module.rds.rds_endpoint
  description = "The endpoint of the PostgreSQL RDS instance"
}

output "rds_sg_id" {
  value = module.rds.rds_sg_id
  description = "Security Group ID for RDS"
}

output "alb_dns_name" {
  value = module.alb.alb_dns
}