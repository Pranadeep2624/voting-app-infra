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
}

/*==========
ArgoCD assume role
==========*/
module "argocd_irsa" {
  source        = "git::https://github.com/Pranadeep2624/terraform-aws-modules.git//IRSA"
  oidc_provider = replace(module.argocd_eks.oidc_url, "https://", "")


  service_account = ["system:serviceaccount:argocd:argocd-server", "system:serviceaccount:argocd:argocd-application-controller"]
  role_name       = "${module.argocd_eks.eks_cluster_name}-argocd-assume-role"
  policy_arns     = []

}
