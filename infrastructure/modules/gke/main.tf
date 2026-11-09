resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region
  network  = var.network_id
  subnetwork = var.subnetwork_id
  
  deletion_protection = false

  node_locations = length(var.cluster_node_locations) > 0 ? var.cluster_node_locations : null

  # Remueve el node pool por defecto y gestiona custom pools
  remove_default_node_pool = var.enable_autopilot ? null : true
  initial_node_count       = var.enable_autopilot ? null : 1

  dynamic "node_config" {
    for_each = var.enable_autopilot ? [] : [1]
    content {
      disk_type    = "pd-standard"
      disk_size_gb = 30
      spot         = true
    }
  }

  # Habilitar Workload Identity (Requerido para Vault y GitOps)
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Configuración de clúster privado
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pod_ip_range_name
    services_secondary_range_name = var.svc_ip_range_name
  }

  # Node Auto-Provisioning (NAP) para FinOps Scale-to-Zero
  dynamic "cluster_autoscaling" {
    for_each = var.enable_nap && !var.enable_autopilot ? [1] : []
    content {
      enabled = true
      resource_limits {
        resource_type = "cpu"
        minimum       = 0
        maximum       = 100
      }
      resource_limits {
        resource_type = "memory"
        minimum       = 0
        maximum       = 500
      }
      auto_provisioning_defaults {
        service_account = google_service_account.cluster_sa.email
        oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
      }
    }
  }

  # Configuración Autopilot (opcional)
  enable_autopilot = var.enable_autopilot ? true : null
}

# Service Account para los nodos
resource "google_service_account" "cluster_sa" {
  account_id   = "${var.cluster_name}-node-sa"
  display_name = "Service Account para nodos de ${var.cluster_name}"
}

# Creación dinámica de Node Pools (ignorado si es Autopilot)
resource "google_container_node_pool" "custom_pools" {
  for_each = { for pool in var.node_pools : pool.name => pool }

  name       = each.value.name
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = each.value.min_count
  node_locations = length(each.value.node_locations) > 0 ? each.value.node_locations : null

  autoscaling {
    min_node_count = each.value.min_count
    max_node_count = each.value.max_count
  }

  node_config {
    machine_type    = each.value.machine_type
    disk_size_gb    = each.value.disk_size_gb
    spot            = each.value.spot
    service_account = google_service_account.cluster_sa.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    labels = each.value.labels

    dynamic "guest_accelerator" {
      for_each = each.value.gpu_type != null && each.value.gpu_count > 0 ? [1] : []
      content {
        type  = each.value.gpu_type
        count = each.value.gpu_count
      }
    }

    dynamic "taint" {
      for_each = each.value.taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
  }

  lifecycle {
    ignore_changes = [
      initial_node_count,
      node_count
    ]
  }
}
