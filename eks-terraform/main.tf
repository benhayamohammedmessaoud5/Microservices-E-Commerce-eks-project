provider "aws" {
  region = "us-east-1"
}

# Récupérer l'ID de votre compte AWS dynamiquement
data "aws_caller_identity" "current" {}

# Définition de l'ARN du rôle existant dans AWS Academy
locals {
  lab_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
}

# ----------------------------
# VPC and Subnet Data Sources
# ----------------------------
data "aws_vpc" "main" {
  tags = {
    Name = "Jumphost-vpc"
  }
}

data "aws_subnet" "subnet-1" {
  vpc_id = data.aws_vpc.main.id
  filter {
    name   = "tag:Name"
    values = ["Public-Subnet-1"]
  }
}

data "aws_subnet" "subnet-2" {
  vpc_id = data.aws_vpc.main.id
  filter {
    name   = "tag:Name"
    values = ["Public-subnet2"]
  }
}

data "aws_security_group" "selected" {
  vpc_id = data.aws_vpc.main.id
  filter {
    name   = "tag:Name"
    values = ["Jumphost-sg"]
  }
}

# ----------------------------
# EKS Cluster
# ----------------------------
resource "aws_eks_cluster" "eks" {
  name     = "project-eks"
  
  # On utilise le rôle pré-existant du Lab
  role_arn = local.lab_role_arn

  vpc_config {
    subnet_ids         = [data.aws_subnet.subnet-1.id, data.aws_subnet.subnet-2.id]
    security_group_ids = [data.aws_security_group.selected.id]
  }

  tags = {
    Name        = "yaswanth-eks-cluster"
    Environment = "dev"
    Terraform   = "true"
  }
}


# ----------------------------
# EKS Node Group
# ----------------------------
resource "aws_eks_node_group" "node-grp" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = var.node_group_name
  
  # On utilise aussi le rôle pré-existant du Lab ici
  node_role_arn   = local.lab_role_arn
  
  subnet_ids      = [data.aws_subnet.subnet-1.id, data.aws_subnet.subnet-2.id]
  capacity_type   = "ON_DEMAND"
  disk_size       = 20
  instance_types  = ["t2.large"]

  labels = {
    env = "dev"
  }

  tags = {
    Name = "project-eks-node-group"
  }

  scaling_config {
    desired_size = 3
    max_size     = 10
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }
}

# ----------------------------
