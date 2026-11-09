output "cluster_name" {
  description = "El nombre del clúster GKE"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "La IP del plano de control"
  value       = google_container_cluster.primary.endpoint
}

output "cluster_ca_certificate" {
  description = "El certificado CA del clúster (base64)"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "workload_identity_pool" {
  description = "El Workload Identity Pool configurado"
  value       = google_container_cluster.primary.workload_identity_config[0].workload_pool
}
