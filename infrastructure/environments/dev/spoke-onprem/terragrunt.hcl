include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/gce-onprem"
}

dependency "networking" {
  config_path = "../networking"
}

inputs = {
  project_id    = "idp-architect"
  region        = "us-central1"
  network_id    = dependency.networking.outputs.spokes_vpc_id
  subnetwork_id = dependency.networking.outputs.spokes_subnet_id
  
  # Topología base de carga: 1 Master y 1 Worker para Desarrollo (ahorro de costos)
  master_count = 1
  worker_count = 1
  machine_type = "e2-micro"
}
