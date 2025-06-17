output "vault_url" {
  value = helm_release.vault.name
}

output "argocd_url" {
  value = helm_release.argocd.name
}

output "ingress_controller_ip" {
  value = helm_release.nginx_ingress.name
}