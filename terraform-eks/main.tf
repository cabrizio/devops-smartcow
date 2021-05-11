##################################################################
# EKS dedicate VPC
##################################################################
module "smartcow-eks-vpc" {
  source = "./modules/vpc"

  name = "isb-QA-smartcow-eks-subnet"

  cidr = "10.10.0.0/16"

  azs             = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  public_subnets  = ["10.10.101.0/24", "10.10.102.0/24", "10.10.103.0/24"]

  enable_ipv6 = false

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true

  public_subnet_tags = {
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/smartcow-eks" = "shared"
    "kubernetes.io/role/elb"           = "1"
  }

  tags = {
    Owner       = "Carmine Fabrizio"
    Team        = "DevOps"
    Environment = "DEV"
  }

  vpc_tags = {
    Name = "isb-QA-smartcow-eks-vpc"
  }
}

##################################################################
# EKS configuration
##################################################################

########################
# EKS policy
########################
resource "aws_iam_role" "smartcow-eks" {
  name = "eks-cluster-smartcow-eks"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "smartcow-eks-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.smartcow-eks.name
}

resource "aws_iam_role_policy_attachment" "smartcow-eks-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.smartcow-eks.name
}

resource "aws_iam_role" "smartcow-eks-group" {
  name = "eks-node-group-smartcow-eks"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "smartcow-eks-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.smartcow-eks-group.name
}

resource "aws_iam_role_policy_attachment" "smartcow-eks-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.smartcow-eks-group.name
}

resource "aws_iam_role_policy_attachment" "smartcow-eks-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.smartcow-eks-group.name
}

#############################
# EKS cluster config
#############################


resource "aws_eks_cluster" "smartcow-eks" {
  name     = "smartcow-eks"
  role_arn = aws_iam_role.smartcow-eks.arn
  version  = "1.18"

  vpc_config {
    subnet_ids = [module.smartcow-eks-vpc.public_subnets[0],module.smartcow-eks-vpc.public_subnets[1],module.smartcow-eks-vpc.public_subnets[2]]
  }

  depends_on = [
    aws_iam_role_policy_attachment.smartcow-eks-AmazonEKSClusterPolicy
  ]

  tags = {
    Owner       = "Carmine Fabrizio"
    Team        = "DevOps"
    Environment = "DEV"
  }
}

resource "aws_eks_node_group" "smartcow-eks" {
  cluster_name    = aws_eks_cluster.smartcow-eks.name
  node_group_name = "smartcow-eks"
  node_role_arn   = aws_iam_role.smartcow-eks-group.arn
  subnet_ids      = module.smartcow-eks-vpc.private_subnets[*]
  // subnet_ids      = aws_subnet.smartcow-eks[*].id

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }
  remote_access {
    ec2_ssh_key     = aws_key_pair.carmine_fabrizio.id
  }

  depends_on = [
    aws_iam_role_policy_attachment.smartcow-eks-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.smartcow-eks-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.smartcow-eks-AmazonEC2ContainerRegistryReadOnly,
  ]
  tags = {
    Owner       = "Carmine Fabrizio"
    Team        = "DevOps"
    Environment = "DEV"
  }
}

output "endpoint" {
  value = aws_eks_cluster.smartcow-eks.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.smartcow-eks.certificate_authority[0].data
}