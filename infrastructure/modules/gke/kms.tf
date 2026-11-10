# ==============================================================================
# Google Cloud KMS para Auto-Unseal de HashiCorp Vault (Zero-Touch)
# ==============================================================================

# Habilitar la API de Cloud KMS en el proyecto de GCP
resource "google_project_service" "kms" {
  count              = var.enable_vault_kms ? 1 : 0
  project            = var.project_id
  service            = "cloudkms.googleapis.com"
  disable_on_destroy = false
}

resource "google_kms_key_ring" "vault" {
  count      = var.enable_vault_kms ? 1 : 0
  name       = "${var.cluster_name}-vault-keyring"
  location   = var.region
  project    = var.project_id
  depends_on = [google_project_service.kms]
}

resource "google_kms_crypto_key" "vault_unseal" {
  count           = var.enable_vault_kms ? 1 : 0
  name            = "vault-unseal-key"
  key_ring        = google_kms_key_ring.vault[0].id
  rotation_period = "7776000s" # 90 días

  lifecycle {
    prevent_destroy = false
  }
}

# Service Account dedicada en GCP para Vault
resource "google_service_account" "vault_kms" {
  count        = var.enable_vault_kms ? 1 : 0
  account_id   = "vault-kms-${var.cluster_name}"
  display_name = "Service Account para Auto-Unseal de Vault en ${var.cluster_name}"
  project      = var.project_id
}

# Otorgar permisos de cifrado/descifrado a la SA sobre la llave KMS de GCP
resource "google_kms_crypto_key_iam_member" "vault_kms" {
  count         = var.enable_vault_kms ? 1 : 0
  crypto_key_id = google_kms_crypto_key.vault_unseal[0].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.vault_kms[0].email}"
}

# Otorgar permisos de lectura (cloudkms.cryptoKeys.get) necesarios para que Vault verifique la llave
resource "google_kms_crypto_key_iam_member" "vault_kms_viewer" {
  count         = var.enable_vault_kms ? 1 : 0
  crypto_key_id = google_kms_crypto_key.vault_unseal[0].id
  role          = "roles/cloudkms.viewer"
  member        = "serviceAccount:${google_service_account.vault_kms[0].email}"
}

# Workload Identity Binding:
# Vincula la Service Account de Kubernetes 'vault' en namespace 'vault' con la SA de GCP
resource "google_service_account_iam_member" "vault_workload_identity" {
  count              = var.enable_vault_kms ? 1 : 0
  service_account_id = google_service_account.vault_kms[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[vault/vault]"
}

