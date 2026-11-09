include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/networking"
}

inputs = {
  project_id = "idp-architect"
  region     = "us-central1"
  
  hub_network_name   = "vpc-hub-dev"
  spoke_network_name = "vpc-spokes-dev"
  
  # CIDRs para el entorno DEV
  hub_subnet_cidr   = "10.0.0.0/20"
  spoke_subnet_cidr = "10.1.0.0/20"
}
