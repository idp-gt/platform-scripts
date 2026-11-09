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
  cluster_name      = "gke-spoke-ai"
  network_id        = dependency.networking.outputs.spokes_vpc_id
  subnetwork_id     = dependency.networking.outputs.spokes_subnet_id
  pod_ip_range_name = "spoke-pods"
  svc_ip_range_name = "spoke-services"
  master_ipv4_cidr_block = "172.16.0.48/28"
  
  enable_nap = true

  node_pools = [
    {
      name         = "ai-gpu-pool"
      machine_type = "g2-standard-4" # Familia G2 para NVIDIA L4
      min_count    = 0               # Puede escalar a cero si no hay entrenamiento/inferencia
      max_count    = 5
      disk_size_gb = 15
      gpu_type     = "nvidia-l4"
      gpu_count    = 1
      node_locations = ["us-central1-a", "us-central1-c"] # Zonas con NVIDIA L4
      labels       = { "layer" = "ai", "accelerator" = "nvidia-l4" }
      taints = [
        {
          key    = "nvidia.com/gpu"
          value  = "present"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  ]
}
