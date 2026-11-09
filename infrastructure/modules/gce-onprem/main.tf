# Data source para obtener la imagen OS más reciente
data "google_compute_image" "os_image" {
  family  = var.image_family
  project = var.image_project
}

# --- MASTER NODES ---
resource "google_compute_instance" "master" {
  count        = var.master_count
  name         = "onprem-master-${count.index + 1}"
  machine_type = var.machine_type
  zone         = element(var.zones, count.index % length(var.zones))

  boot_disk {
    initialize_params {
      image = data.google_compute_image.os_image.self_link
      size  = 15
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = var.network_id
    subnetwork = var.subnetwork_id
    # Sin IP pública externa (arquitectura privada pura)
  }

  tags = ["k8s-master", "onprem-cluster"]

  metadata = {
    ssh-keys = "ubuntu:..." # Aquí se inyectarían las llaves SSH para Ansible
  }

  scheduling {
    provisioning_model = "SPOT"
    preemptible        = true
    automatic_restart  = false
  }
}

# --- WORKER NODES ---
resource "google_compute_instance" "worker" {
  count        = var.worker_count
  name         = "onprem-worker-${count.index + 1}"
  machine_type = var.machine_type
  zone         = element(var.zones, count.index % length(var.zones))

  boot_disk {
    initialize_params {
      image = data.google_compute_image.os_image.self_link
      size  = 15
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = var.network_id
    subnetwork = var.subnetwork_id
  }

  tags = ["k8s-worker", "onprem-cluster"]

  scheduling {
    provisioning_model = "SPOT"
    preemptible        = true
    automatic_restart  = false
  }
}

# --- INTERNAL LOAD BALANCER PARA KUBE-APISERVER ---

# Instance Group para los Masters
resource "google_compute_instance_group" "master_group" {
  count     = length(var.zones)
  name      = "onprem-master-ig-${element(var.zones, count.index)}"
  zone      = element(var.zones, count.index)
  network   = var.network_id
  instances = [
    for inst in google_compute_instance.master : inst.self_link if inst.zone == element(var.zones, count.index)
  ]
}

# Health Check para API Server
resource "google_compute_health_check" "api_hc" {
  name = "onprem-api-hc"
  tcp_health_check {
    port = 6443
  }
}

# Backend Service Interno (L4)
resource "google_compute_region_backend_service" "api_backend" {
  name                  = "onprem-api-backend"
  region                = var.region
  health_checks         = [google_compute_health_check.api_hc.id]
  load_balancing_scheme = "INTERNAL"

  dynamic "backend" {
    for_each = google_compute_instance_group.master_group
    content {
      group = backend.value.id
    }
  }
}

# Forwarding Rule (Virtual IP para el API Server)
resource "google_compute_forwarding_rule" "api_vip" {
  name                  = "onprem-api-vip"
  region                = var.region
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.api_backend.id
  ports                 = ["6443"]
  network               = var.network_id
  subnetwork            = var.subnetwork_id
}

# Instance Group para los Workers (usado por el LB Global)
resource "google_compute_instance_group" "worker_group" {
  name      = "onprem-worker-ig"
  zone      = element(var.zones, 0)
  network   = var.network_id
  instances = [
    for inst in google_compute_instance.worker : inst.self_link if inst.zone == element(var.zones, 0)
  ]
}
