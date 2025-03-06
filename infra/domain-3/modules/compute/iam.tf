

# ********* EKS cluster IAM Role ***********
resource "aws_iam_role" "cluster_role" {
  name               = "${var.cluster_name}-iam-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume.json
}
# ***** cluster policy documents ********
data "aws_iam_policy_document" "cluster_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "cluster_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}

# ************ EKS Node Group IAM Role *********
resource "aws_iam_role" "worker_role" {
  name               = "${var.eks_node_group_name}-iam-role"
  assume_role_policy = data.aws_iam_policy_document.worker_assume_role.json
}
# ***** worker policy document ********
data "aws_iam_policy_document" "worker_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# ******** attach required policies to workers ***************
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