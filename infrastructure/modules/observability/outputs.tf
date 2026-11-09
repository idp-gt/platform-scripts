output "namespace" {
  description = "Namespace donde corre Grafana Alloy"
  value       = var.namespace
}

output "release_name" {
  description = "Nombre de la release de Helm"
  value       = helm_release.grafana_alloy.name
}
