include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/global-lb"
}

# Dependencia del On-Premise Spoke Base para obtener el Instance Group
dependency "onprem" {
  config_path = "../spoke-onprem"
  
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "destroy"]
  mock_outputs = { 
    worker_instance_group_id = "mock-id" 
  }
}

inputs = {
  project_id = "idp-architect"
  lb_name    = "hybrid-finops-lb"
  
  # Asumimos que los workers del on-prem son el backend
  onprem_instance_group = dependency.onprem.outputs.worker_instance_group_id
  
  # El gke_neg_id se dejaría en blanco o se conectaría tras desplegar Ingress en GKE
  gke_neg_id = "" 
}
