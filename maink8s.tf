provider "aws" {
  region = "us-east-1"  # Change this to your desired AWS region
}

resource "aws_eks_cluster" "example" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = aws_subnet.private.*.id
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster]
}

resource "aws_eks_node_group" "example" {
  cluster_name    = aws_eks_cluster.example.name
  node_group_name = "my-eks-nodegroup"

  node_role_arn = aws_iam_role.eks_nodegroup.arn

  subnet_ids = aws_subnet.private.*.id

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }
}

resource "aws_iam_role" "eks_cluster" {
  name = "my-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role" "eks_nodegroup" {
  name = "my-eks-nodegroup-role"

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
}

resource "aws_iam_instance_profile" "eks_nodegroup" {
  name = "my-eks-nodegroup-profile"
  role = aws_iam_role.eks_nodegroup.name
}

resource "aws_subnet" "private" {
  count           = 2
  cidr_block      = "10.0.${count.index + 1}.0/24"
  availability_zone = "us-east-1a"  # Change this to your desired AZ
  vpc_id          = aws_vpc.example.id
}

resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

output "kubeconfig" {
  value = aws_eks_cluster.example.kubeconfig
}
