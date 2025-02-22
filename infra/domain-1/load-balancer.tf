# *************** Load Balancer ******************
# -> connect helm provider to the eks cluster for load balancer deployemnt* 
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.master.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.master.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
      command     = "aws"
    }
  }
}
# -> connect k8s provider to the cluster to deploy service account 
# -> for the aws load balancer controller 
provider "kubernetes" {
  host                   = aws_eks_cluster.master.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.master.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
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
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = aws_vpc.main.id
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
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

# -> service accounts for laod balancer 
resource "kubernetes_service_account" "service_account" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = module.lb_role.iam_role_arn
    }
  }
}

locals {
  account_id   = data.aws_caller_identity.current.account_id
  cluster_oidc = basename(aws_eks_cluster.master.identity[0].oidc[0].issuer)
}

data "aws_caller_identity" "current" {}

# resource "kubernetes_config_map" "config_map" {
#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }

#   # data = {
#   #   groups   = "- system:masters"
#   #   rolearn  = aws_iam_role.codebuild_role.arn
#   #   username = aws_iam_role.codebuild_role.name
#   # }
#   data = {
#   mapRoles = <<EOF
#     - groups:
#       - system:masters
#       rolearn: ${aws_iam_role.codebuild_role.arn}
#       username: ${aws_iam_role.codebuild_role.name}
#     EOF
#     }
# }

