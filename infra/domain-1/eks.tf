# ********* EKS Cluster ****************
resource "aws_eks_cluster" "master" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster_role.arn
  vpc_config {
    subnet_ids = local.subnet_ids
  }

  depends_on = [aws_iam_role_policy_attachment.cluster_policy]
}

#********** EKS cluster node group ******************
resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.master.name
  node_group_name = var.node_gname
  node_role_arn   = aws_iam_role.worker_role.arn
  subnet_ids      = local.subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 2
  }

  instance_types = ["t2.medium"]

  depends_on = [
    aws_iam_role_policy_attachment.worker_policy_attach,
    aws_iam_role_policy_attachment.ec2_policy_attach,
    aws_iam_role_policy_attachment.eks_cni_policy_attach
  ]
}

# ******* subnets for EKS cluster **************
locals {
  subnet_ids = flatten([
    [for idx in range(0, 3) : aws_subnet.public[idx].id],
    [for idx in range(0, 3) : aws_subnet.private[idx].id]
  ])
}

#********** cluster OIDC provider ************
resource "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  url            = aws_eks_cluster.master.identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]
}

# *************************** EKS IAM ************************ # 
# Create IAM role for EKS cluster
resource "aws_iam_role" "cluster_role" {
  name               = "CreatedEKSClusterRole"
  assume_role_policy = data.aws_iam_policy_document.cluster_role.json
}

data "aws_iam_policy_document" "cluster_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Create IAM role for worker nodes
resource "aws_iam_role" "worker_role" {
  name               = "CreatedEKSWorkerRole"
  assume_role_policy = data.aws_iam_policy_document.worker_role.json
}

data "aws_iam_policy_document" "worker_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# attach managed policies ( ec2, cni, eksWorker ) to worker role 
resource "aws_iam_role_policy_attachment" "worker_policy_attach" {
  role       = aws_iam_role.worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "ec2_policy_attach" {
  role       = aws_iam_role.worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_role_policy_attachment" "eks_cni_policy_attach" {
  role       = aws_iam_role.worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}