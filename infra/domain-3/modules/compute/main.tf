
# ***** eks cluste *******
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster_role.arn
  vpc_config {
    subnet_ids = var.subnet_ids
  }
}

# ******** EKS Node Group ***************
resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = var.eks_node_group_name
  node_role_arn   = aws_iam_role.worker_role.arn
  subnet_ids      = var.subnet_ids
  instance_types  = [var.worker_instance_type] #"t2.medium"
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 2
  }
}
