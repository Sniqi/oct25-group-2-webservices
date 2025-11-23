variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the instance will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be deployed"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

resource "aws_security_group" "app_sg" {
  name        = "dataops-${var.environment}-sg"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # In production, restrict this to your IP!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "dataops-${var.environment}-sg"
    Environment = var.environment
  }
}

resource "aws_instance" "app_server" {
  ami           = "ami-06dd92ecc74fdfb36" # Ubuntu 22.04 LTS in eu-central-1 (Frankfurt). Check for other regions!
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y docker.io
              systemctl start docker
              systemctl enable docker
              docker run -d -p 80:8000 sniqi/dataops-demo:dev-latest
              EOF

  tags = {
    Name        = "dataops-${var.environment}-app"
    Environment = var.environment
  }
}

output "public_ip" {
  value = aws_instance.app_server.public_ip
}
