# Health Check global para detectar si el clúster On-Premise está saturado o caído
resource "google_compute_health_check" "hybrid_hc" {
  name               = "${var.lb_name}-hc"
  timeout_sec        = 5
  check_interval_sec = 5
  http_health_check {
    port         = 80
    request_path = "/healthz"
  }
}

# Backend Service Global
resource "google_compute_backend_service" "hybrid_backend" {
  name                  = "${var.lb_name}-backend"
  health_checks         = [google_compute_health_check.hybrid_hc.id]
  load_balancing_scheme = "EXTERNAL"
  protocol              = "HTTP"

  # El backend principal: On-Premise (100% capacidad base)
  backend {
    group           = var.onprem_instance_group
    balancing_mode  = "RATE"
    max_rate_per_instance = 100 # Define el límite antes del failover/bursting
  }

  # El backend secundario: Cloud Spoke GKE (solo recibe tráfico si On-Prem satura)
  # Este bloque solo se activa si se provee el NEG del Ingress de GKE.
  dynamic "backend" {
    for_each = var.gke_neg_id != "" ? [1] : []
    content {
      group           = var.gke_neg_id
      balancing_mode  = "RATE"
      max_rate_per_endpoint = 500
    }
  }
}

# URL Map (Router Global)
resource "google_compute_url_map" "hybrid_url_map" {
  name            = "${var.lb_name}-url-map"
  default_service = google_compute_backend_service.hybrid_backend.id
}

# HTTP Proxy
resource "google_compute_target_http_proxy" "hybrid_http_proxy" {
  name    = "${var.lb_name}-http-proxy"
  url_map = google_compute_url_map.hybrid_url_map.id
}

# IP Pública Global (Anycast)
resource "google_compute_global_address" "hybrid_ip" {
  name = "${var.lb_name}-ip"
}

# Regla de Reenvío Global (Frontend)
resource "google_compute_global_forwarding_rule" "hybrid_frontend" {
  name                  = "${var.lb_name}-frontend"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_http_proxy.hybrid_http_proxy.id
  ip_address            = google_compute_global_address.hybrid_ip.id
}
