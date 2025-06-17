resource "helm_release" "vault" {
  name       = "vault"
  namespace  = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"

  values = [
    file("../helm-values/vault-values.yaml")
  ]
}

resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
}