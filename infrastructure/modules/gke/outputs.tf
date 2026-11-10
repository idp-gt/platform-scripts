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

output "vault_kms_key_ring" {
  description = "Nombre del KeyRing de KMS para Vault"
  value       = var.enable_vault_kms ? google_kms_key_ring.vault[0].name : null
}

output "vault_kms_crypto_key" {
  description = "Nombre de la CryptoKey de KMS para Vault"
  value       = var.enable_vault_kms ? google_kms_crypto_key.vault_unseal[0].name : null
}

output "vault_kms_service_account_email" {
  description = "Email de la Service Account de GCP para Vault KMS"
  value       = var.enable_vault_kms ? google_service_account.vault_kms[0].email : null
}
