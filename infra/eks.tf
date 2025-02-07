data "aws_caller_identity" "current" {

}
module "eks" {
  source                      = "git::https://github.com/Pranadeep2624/terraform-aws-modules.git//EKS"
  environment                 = var.environment
  app_name                    = var.app_name
  eks_version                 = var.eks_version
  subnet_ids                  = module.vpc.private_subnets_id
  eks_instance_type           = var.eks_instance_type
  eks_desired_size            = var.eks_desired_size
  eks_min_size                = var.eks_min_size
  eks_max_size                = var.eks_max_size
  eks_endpoint_private_access = var.eks_endpoint_private_access
  eks_endpoint_public_access  = var.eks_endpoint_public_access
  depends_on                  = [module.vpc]
}

resource "aws_ecr_repository" "voting_app_ecrs" {
  for_each             = toset(var.applications)
  name                 = each.value
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "kubernetes_config_map_v1_data" "aws_auth" {

  force = true

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data       = local.aws_auth_configmap_data
  depends_on = [module.eks]

}
locals {
  aws_auth_configmap_data = {
    mapRoles    = yamlencode(local.aws_auth_roles)
    mapUsers    = yamlencode(local.aws_auth_users)
    mapAccounts = yamlencode(local.aws_auth_accounts)
  }
  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/tfc-role"
      username = "adminrole"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "${module.eks.eks_node_iam_role_arn}"
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    },
    {
      rolearn  = "${module.register-apps.argocd_role_arn}"
      username = "argocdrole"
      groups   = ["system:masters"]
    }
    
  ]
  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/AdminUserPranadeep"
      username = "AdminUserPranadeep"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      username = "AdminUserPranadeep"
      groups   = ["system:masters"]
    }
  ]
  aws_auth_accounts = []
}

module "controller" {
  source             = "git::https://github.com/Pranadeep2624/terraform-aws-modules.git//AWSALBController"
  oidc_url           = module.eks.oidc_url
  cluster_name       = module.eks.eks_cluster_name
  app_version = helm_release.aws_alb_controller.metadata[0].app_version
  app_name           = var.app_name
  environment        = var.environment
  namespace          = var.namespace
  service_account    = var.service_account
  depends_on = [ module.eks ]
}

locals {
  mandatory_helm_chart_values = {
    "clusterName"                                               = module.eks.eks_cluster_name
    "serviceAccount.name"                                       = var.service_account
    "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn" = module.controller.irsa_role_arn
  }

}

resource "helm_release" "aws_alb_controller" {
  name = "aws-load-balancer-controller"

  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  create_namespace = var.namespace != "kube-system" ? true : false
  version          = var.controller_version
  namespace        = var.namespace

  cleanup_on_fail = true

  dynamic "set" {
    for_each = local.mandatory_helm_chart_values
    iterator = helm_key_value
    content {
      name  = helm_key_value.key
      value = helm_key_value.value
    }
  }
  
}

