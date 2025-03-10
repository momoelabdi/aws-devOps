

#*** network module ( vpc, subnets, route tables, etc ) for eks cluster ****
module "network" {
  source          = "./modules/networking"
  public_subnets  = 3
  private_subnets = 3
  cluster_name    = var.cluster_name
}

# ******* EKS cluster ********
module "eks" {
  source               = "./modules/compute"
  cluster_name         = var.cluster_name
  eks_node_group_name  = var.eks_node_group_name
  worker_instance_type = var.worker_instance_type
  subnet_ids           = module.network.private_subnets_ids
  vpc_id               = module.network.vpc_id
}

# ******** DB for service on EKS cluster ************
module "storage" {
  source              = "./modules/storage"
  private_subnets_ids = module.network.private_subnets_ids
  db_subnet_name      = var.db_subnet_name
  vpc_id              = module.network.vpc_id
  db_instance_type    = var.db_instance_type
  db_identifier       = var.db_identifier
  db_username         = var.db_username
  db_password         = var.db_password
}
