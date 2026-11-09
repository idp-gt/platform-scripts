include "root" {
  path = find_in_parent_folders()
}

locals {
  env_vars = yamldecode(file("${find_in_parent_folders("env.yaml")}"))
}



terraform {
  source = "../../../modules/gke"
}

dependency "networking" {
  config_path = "../networking"
}

inputs = {
  project_id        = "idp-architect"
  region            = "us-central1"
  cluster_name      = "gke-spoke-data"
  network_id        = dependency.networking.outputs.spokes_vpc_id
  subnetwork_id     = dependency.networking.outputs.spokes_subnet_id
  pod_ip_range_name = "spoke-pods"
  svc_ip_range_name = "spoke-services"
  master_ipv4_cidr_block = "172.16.0.32/28"
  
  enable_nap = true

  node_pools = [
    {
      name         = "data-processing-pool"
      machine_type = "e2-medium" # Reducido al mínimo por dev
      min_count    = 1
      max_count    = 10
      disk_size_gb = 15
      labels       = { "layer" = "data", "role" = "processing" }
    }
  ]
}
