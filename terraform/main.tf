module "k8s_cluster" {
  source = "./modules/k8s"  // Optional if using managed services
  # add your VM/cloud config here
}

module "vault" {
  source = "./modules/vault"
}

module "argocd" {
  source = "./modules/argocd"
}

module "ingress" {
  source = "./modules/ingress"
}
