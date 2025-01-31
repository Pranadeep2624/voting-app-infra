module "eks" {
  source          = "git::https://github.com/Pranadeep2624/aws-service-modules.git//EKS"
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