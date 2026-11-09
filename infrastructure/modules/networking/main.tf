# VPC para el Hub Cluster
resource "google_compute_network" "hub_vpc" {
  name                    = var.hub_network_name
  auto_create_subnetworks = false
}

# Subred para el Hub
resource "google_compute_subnetwork" "hub_subnet" {
  name          = "subnet-hub"
  ip_cidr_range = var.hub_subnet_cidr
  region        = var.region
  network       = google_compute_network.hub_vpc.id

  # Alias IPs para Pods y Services en GKE
  secondary_ip_range {
    range_name    = "hub-pods"
    ip_cidr_range = "10.10.0.0/16"
  }
  secondary_ip_range {
    range_name    = "hub-services"
    ip_cidr_range = "10.11.0.0/20"
  }
}

# VPC Compartida para los Spokes (Data, AI, Base)
resource "google_compute_network" "spokes_vpc" {
  name                    = var.spoke_network_name
  auto_create_subnetworks = false
}

# Subred para los Spokes (en la misma región, pero podría dividirse)
resource "google_compute_subnetwork" "spokes_subnet" {
  name          = "subnet-spokes"
  ip_cidr_range = var.spoke_subnet_cidr
  region        = var.region
  network       = google_compute_network.spokes_vpc.id

  secondary_ip_range {
    range_name    = "spoke-pods"
    ip_cidr_range = "10.20.0.0/16"
  }
  secondary_ip_range {
    range_name    = "spoke-services"
    ip_cidr_range = "10.21.0.0/20"
  }
}

# VPC Peering entre Hub y Spokes (Simulando Zero-Trust)
resource "google_compute_network_peering" "hub_to_spokes" {
  name         = "peer-hub-to-spokes"
  network      = google_compute_network.hub_vpc.self_link
  peer_network = google_compute_network.spokes_vpc.self_link
}

resource "google_compute_network_peering" "spokes_to_hub" {
  name         = "peer-spokes-to-hub"
  network      = google_compute_network.spokes_vpc.self_link
  peer_network = google_compute_network.hub_vpc.self_link
}

# Cloud Router y NAT para salida a Internet desde IPs privadas
resource "google_compute_router" "hub_router" {
  name    = "router-hub"
  region  = var.region
  network = google_compute_network.hub_vpc.id
}

resource "google_compute_router_nat" "hub_nat" {
  name                               = "nat-hub"
  router                             = google_compute_router.hub_router.name
  region                             = google_compute_router.hub_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_router" "spokes_router" {
  name    = "router-spokes"
  region  = var.region
  network = google_compute_network.spokes_vpc.id
}

resource "google_compute_router_nat" "spokes_nat" {
  name                               = "nat-spokes"
  router                             = google_compute_router.spokes_router.name
  region                             = google_compute_router.spokes_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Firewall: Permitir tráfico interno
resource "google_compute_firewall" "allow_internal_hub" {
  name    = "fw-allow-internal-hub"
  network = google_compute_network.hub_vpc.name

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = [var.hub_subnet_cidr, var.spoke_subnet_cidr]
}

resource "google_compute_firewall" "allow_internal_spokes" {
  name    = "fw-allow-internal-spokes"
  network = google_compute_network.spokes_vpc.name

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = [var.hub_subnet_cidr, var.spoke_subnet_cidr]
}
