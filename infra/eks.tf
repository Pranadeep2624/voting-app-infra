data "aws_caller_identity" "current" {
  
}


module "eks" {
  source          = "git::https://github.com/Pranadeep2624/terraform-aws-modules.git//EKS"
  environment     = var.environment
  app_name        = var.app_name
  eks_version = var.eks_version
  subnet_ids = module.vpc.private_subnets_id
  eks_instance_type = var.eks_instance_type
  eks_desired_size = var.eks_desired_size
  eks_min_size = var.eks_min_size
  eks_max_size = var.eks_max_size
  eks_endpoint_private_access = var.eks_endpoint_private_access
  eks_endpoint_public_access = var.eks_endpoint_public_access
  depends_on = [ module.vpc ]
}

resource "aws_ecr_repository" "voting_app_ecrs" {
    for_each = toset(var.applications)
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

  data = local.aws_auth_configmap_data
  depends_on = [ module.eks ]
  
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
        rolearn = "${module.eks.eks_node_iam_role_arn}"
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = ["system:bootstrappers","system:nodes"]
    }
  ]
  aws_auth_users = [
    {
        userarn  =  "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/AdminUserPranadeep"
      username = "AdminUserPranadeep"
      groups   = ["system:masters"]
    }
  ]
  aws_auth_accounts = []
}