terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">=2.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">2.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">4.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    argocd = {
      source  = "argoproj-labs/argocd"
      version = ">=7.0.3"
    }
  }
}

provider "aws" {
  region = var.region
}
data "aws_eks_cluster_auth" "cluster_auth" {
  name = module.eks.eks_cluster_name
}
provider "helm" {
  kubernetes {
    host                   = module.eks.endpoint
    cluster_ca_certificate = base64decode(module.eks.eks_cluster_cert_authority)
    token = data.aws_eks_cluster_auth.cluster_auth.token
  }


}
provider "kubernetes" {
  host                   = module.eks.endpoint
  cluster_ca_certificate = base64decode(module.eks.eks_cluster_cert_authority)
  token = data.aws_eks_cluster_auth.cluster_auth.token
}
