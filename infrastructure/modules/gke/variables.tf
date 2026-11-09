variable "project_id" {
  description = "El ID del proyecto de GCP"
  type        = string
}

variable "region" {
  description = "La región principal donde se desplegará el clúster"
  type        = string
}

variable "cluster_name" {
  description = "El nombre del clúster GKE"
  type        = string
}

variable "network_id" {
  description = "El ID (self_link) de la VPC"
  type        = string
}

variable "subnetwork_id" {
  description = "El ID (self_link) de la subred"
  type        = string
}

variable "pod_ip_range_name" {
  description = "Nombre del rango secundario para Pods"
  type        = string
}

variable "svc_ip_range_name" {
  description = "Nombre del rango secundario para Services"
  type        = string
}

variable "master_ipv4_cidr_block" {
  description = "Bloque CIDR para el plano de control (Master)"
  type        = string
  default     = "172.16.0.0/28"
}

variable "node_pools" {
  description = "Lista de objetos definiendo los pools de nodos"
  type = list(object({
    name         = string
    machine_type = string
    min_count    = number
    max_count    = number
    disk_size_gb = number
    gpu_type     = optional(string)
    gpu_count    = optional(number, 0)
    spot         = optional(bool, true)
    node_locations = optional(list(string), [])
    labels       = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  default = []
}

variable "enable_autopilot" {
  description = "Si es verdadero, creará un clúster Autopilot en lugar de Standard"
  type        = bool
  default     = false
}

variable "enable_nap" {
  description = "Habilitar Node Auto-Provisioning (Scale-to-Zero)"
  type        = bool
  default     = true
}

variable "cluster_node_locations" {
  description = "Zonas específicas dentro de la región para los nodos del clúster"
  type        = list(string)
  default     = []
}
