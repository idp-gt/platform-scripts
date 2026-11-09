variable "project_id" {
  description = "El ID del proyecto de GCP"
  type        = string
}

variable "lb_name" {
  description = "Nombre del Global Load Balancer"
  type        = string
  default     = "hybrid-global-lb"
}

variable "onprem_instance_group" {
  description = "ID del Instance Group del Ingress de On-Premise"
  type        = string
}

variable "gke_neg_id" {
  description = "ID del Network Endpoint Group (NEG) del Cloud Spoke GKE"
  type        = string
  default     = ""
}
