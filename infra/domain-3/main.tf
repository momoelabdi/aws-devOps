

#*** network module ( vpc, subnets, route tables, etc ) for eks cluster ****
module "network" {
  source         = "./modules/networking"
  public_subnets = 3
  private_subnets = 3
}

# ******* EKS cluster ********
module "eks" {
  source       = "./modules/compute"
  cluster_name = var.cluster_name 
  eks_node_group_name = var.eks_node_group_name
  worker_instance_type =  var.worker_instance_type
  subnet_ids   = module.network.private_subnets_ids
}

module "storage" {
  source = "./modules/storage"
}
