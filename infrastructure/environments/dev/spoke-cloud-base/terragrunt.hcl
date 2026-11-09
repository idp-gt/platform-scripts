include "root" {
  path = find_in_parent_folders()
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
  cluster_name      = "gke-spoke-base"
  network_id        = dependency.networking.outputs.spokes_vpc_id
  subnetwork_id     = dependency.networking.outputs.spokes_subnet_id
  pod_ip_range_name = "spoke-pods"
  svc_ip_range_name = "spoke-services"
  master_ipv4_cidr_block = "172.16.0.16/28"
  
  # Este Spoke utiliza NAP para Scale-to-Zero puro (Bursting Híbrido)
  enable_nap = true

  node_pools = [
    {
      name         = "burst-pool"
      machine_type = "e2-medium"
      min_count    = 0   # Configuración de Costo Base Cero (FinOps)
      max_count    = 20
      disk_size_gb = 15
      labels       = { "role" = "hybrid-bursting" }
    }
  ]
}
