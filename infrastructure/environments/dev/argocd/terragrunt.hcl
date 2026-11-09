include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/argocd"
}

dependency "hub" {
  config_path = "../hub"
  
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs = {
    cluster_name           = "mock-cluster"
    cluster_endpoint       = "0.0.0.0"
    cluster_ca_certificate = "bW9jay1jYQ=="
  }
}

generate "provider_helm" {
  path      = "provider_helm.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
data "google_client_config" "default" {}

provider "helm" {
  kubernetes {
    host                   = "https://${dependency.hub.outputs.cluster_endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode("${dependency.hub.outputs.cluster_ca_certificate}")
  }
}
EOF
}

inputs = {
  project_id   = "idp-architect"
  cluster_name = dependency.hub.outputs.cluster_name
}
