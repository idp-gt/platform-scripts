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
  cluster_name      = "gke-hub-cluster"
  network_id        = dependency.networking.outputs.hub_vpc_id
  subnetwork_id     = dependency.networking.outputs.hub_subnet_id
  pod_ip_range_name = "hub-pods"
  svc_ip_range_name = "hub-services"
  master_ipv4_cidr_block = "172.16.1.0/28"
  cluster_node_locations = ["us-central1-a"]
  
  # El Hub NO escala a cero (aloja ArgoCD, Vault, IDP)
  enable_nap = false

  node_pools = [
    {
      name         = "platform-pool"
      machine_type = "e2-medium"
      min_count    = 2
      max_count    = 5
      disk_size_gb = 30
      node_locations = ["us-central1-a"]
      labels       = { "role" = "platform-management" }
    }
  ]
}
