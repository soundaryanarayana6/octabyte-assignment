# Security group for EC2
resource "aws_security_group" "web_sg" {
  name        = "${var.env}-web-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}

# EC2 instances
resource "aws_instance" "web" {
  count         = length(var.public_subnet_ids)
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.public_subnet_ids[count.index]
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name      = var.key_name
  associate_public_ip_address = true 

  user_data = <<-EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl enable httpd
systemctl start httpd
echo "<h1>Terraform Web Server - $(hostname)</h1>" > /var/www/html/index.html
EOF

  tags = {
    Name = "${var.env}-web-${count.index + 1}"
  }
}


