output "instance_ids" {
  value = aws_instance.web[*].id
}

output "instance_public_ips" {
  value = aws_instance.web[*].public_ip
}

output "ec2_ids" {
  value = aws_instance.web[*].id
}

output "ec2_sg_id" {
  value = aws_security_group.web_sg.id
}

output "web_sg_id" {
  value = aws_security_group.web_sg.id
}
