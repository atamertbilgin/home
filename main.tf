provider "aws" {
  region = "us-east-1"  # Replace with your desired AWS region
}

resource "aws_security_group" "k8s_sg" {
  name_prefix = "k8s-sg-"

  ingress {
    from_port   = 22   # SSH port
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH access from anywhere (this can be restricted to your IP later)
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }
}

resource "aws_instance" "k8s_instance" {
  ami           = "ami-0f34c5ae932e6f0e4"  # Replace with the AMI ID for your desired Jenkins image
  instance_type = "t3a.medium"  # Replace with your desired instance type

  key_name      = "first-key"  # Replace with the name of your EC2 key pair

  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  tags = {
    Name = "K8s Instance"
  }

  # Add IAM instance profile to associate with the EC2 instance
  iam_instance_profile = aws_iam_instance_profile.k8s_instance_profile.name

}

# Create the IAM instance profile and associate it with the "AmazonEC2FullAccess" policy
resource "aws_iam_instance_profile" "k8s_instance_profile" {
  name = "k8s-instance-profile"

  role = aws_iam_role.k8s_instance_role.name
}

# Attach the "AmazonEC2FullAccess" policy to the IAM role
resource "aws_iam_role" "k8s_instance_role" {
  name = "k8s-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  # Attach the "AmazonEC2FullAccess" and "AmazonEC2ContainerRegistryFullAccess" managed policies to the IAM role
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  ]
}


output "k8s_public_ip" {
  value = aws_instance.k8s_instance.public_ip
}
