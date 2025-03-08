
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
  instance_types  = [var.worker_instance_type] 
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 2
  }
}

#********** cluster OIDC provider ************
resource "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  url            = aws_eks_cluster.main.identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]
}


provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
    exec {
      api_version = var.api_version
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
      command     = "aws"
    }
  }
}

# -> deploy aws load balancer controller.
resource "helm_release" "lb" {
  name       = var.load_balancer_controller_name
  repository = var.load_balancer_repo_url
  chart      = var.load_balancer_controller_name
  namespace  = "kube-system"
  depends_on = [
    kubernetes_service_account.service_account
  ]

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "image.repository"
    value = var.load_balancer_image
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = var.load_balancer_controller_name
  }

  set {
    name  = "clusterName"
    value = var.cluster_name
  }
}

# -> IAM Role for service accounts
module "lb_role" {
  source                                 = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name                              = "${var.cluster_name}-lb"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = aws_iam_openid_connect_provider.eks_oidc_provider.arn
      namespace_service_accounts = ["kube-system:${var.load_balancer_controller_name}"]
    }
  }
}

# -> connect k8s provider to the cluster to deploy service account 
# -> for the aws load balancer controller 
provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  exec {
    api_version = var.api_version
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }
}

# -> service accounts for laod balancer 
resource "kubernetes_service_account" "service_account" {
  metadata {
    name      = var.load_balancer_controller_name
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = var.load_balancer_controller_name
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = module.lb_role.iam_role_arn
    }
  }
}

