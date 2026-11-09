variable "project_id" {
  description = "ID del proyecto en Google Cloud"
  type        = string
  default     = "idp-architect"
}

variable "namespace" {
  description = "Namespace donde se desplegará Grafana Alloy"
  type        = string
  default     = "grafana-observability"
}

variable "grafana_cloud_prometheus_url" {
  description = "URL del endpoint de Prometheus Remote Write en Grafana Cloud (ej. https://prometheus-prod-XX.grafana.net/api/prom/push)"
  type        = string
  default     = ""
}

variable "grafana_cloud_prometheus_user" {
  description = "User ID / Instance ID de Prometheus en Grafana Cloud"
  type        = string
  default     = ""
}

variable "grafana_cloud_prometheus_token" {
  description = "API Token con permiso metrics:write en Grafana Cloud"
  type        = string
  default     = ""
  sensitive   = true
}

variable "scrape_interval" {
  description = "Intervalo de scraping para las métricas de Argo CD"
  type        = string
  default     = "30s"
}
