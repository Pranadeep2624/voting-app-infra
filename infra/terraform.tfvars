region          = "us-east-1"
environment     = "dev"
app_name        = "votingapp"
cidr_base       = "10.0.0.0/16"
public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnets = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
create_nat      = true
applications    = ["voting-app", "result-app", "worker"]

/*====
EKS variables
=====*/
eks_version                 = "1.30"
eks_instance_type           = "t2.large"
eks_desired_size            = "1"
eks_min_size                = "1"
eks_max_size                = "1"
eks_endpoint_private_access = false
eks_endpoint_public_access  = true

/*====
AWSALBController variables
=====*/
namespace          = "kube-system"
service_account    = "aws-alb-controller-sa"
controller_version = "1.10.1"
