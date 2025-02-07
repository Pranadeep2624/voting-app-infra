resource "helm_release" "argocd" {
  name = "argocd"

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  timeout          = 600
  version          = "7.7.7"
  cleanup_on_fail  = true
  values           = [file("./values.yaml")]
  
  set {
    name  = "server.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.argocd_irsa.role_arn
  }
  set {
    name  = "controller.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.argocd_irsa.role_arn
  }
  depends_on = [ module.eks ]
}

/*==========
ArgoCD assume role
==========*/
module "argocd_irsa" {
  source        = "git::https://github.com/Pranadeep2624/terraform-aws-modules.git//IRSA"
  oidc_provider = replace(module.eks.oidc_url, "https://", "")


  service_account = ["system:serviceaccount:argocd:argocd-server", "system:serviceaccount:argocd:argocd-application-controller"]
  role_name       = "${module.eks.eks_cluster_name}-argocd-assume-role"
  policy_arns     = []
depends_on = [ module.eks ]
}

resource "helm_release" "register_app_of_apps" {
  name = "app-of-apps"

  repository       = "./charts"
  chart            = "votingapp-app-of-apps"
  create_namespace =  false
  namespace        = "argocd"

  cleanup_on_fail = true

  values = [templatefile("./app-of-apps.yaml", {
    repo-token = var.repo-token,
    server-url = module.eks.endpoint
    
  })]
  depends_on = [ helm_release.argocd , module.register-apps ]
}
/*=====
Creating IAM Role for argocd management role to assume to access cluster
======*/
module "register-apps" {
  source = "git::https://github.com/Pranadeep2624/terraform-aws-modules.git//ArgoCDClusterConnect"
  argocd_management_role_arn = module.argocd_irsa.role_arn
  cluster_endpoint = module.eks.endpoint
  cluster_name = module.eks.eks_cluster_name
  cluster_certificate_authority_data = module.eks.eks_cluster_cert_authority
  cluster_connect_secret_name = module.eks.eks_cluster_name
  namespace = "argocd"
}
