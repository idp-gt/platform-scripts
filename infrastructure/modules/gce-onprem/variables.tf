variable "project_id" {
  description = "El ID del proyecto de GCP"
  type        = string
}

variable "region" {
  description = "La región para las instancias (ej. us-central1)"
  type        = string
}

variable "zones" {
  description = "Zonas donde se distribuirán los nodos (ej. a, b, c)"
  type        = list(string)
  default     = ["us-central1-a", "us-central1-b", "us-central1-c"]
}

variable "network_id" {
  description = "ID de la VPC (Spokes)"
  type        = string
}

variable "subnetwork_id" {
  description = "ID de la Subred"
  type        = string
}

variable "master_count" {
  description = "Número de nodos Master (Control Plane) - Debe ser impar (ej. 3)"
  type        = number
  default     = 3
}

variable "worker_count" {
  description = "Número de nodos Worker"
  type        = number
  default     = 3
}

variable "machine_type" {
  description = "Tipo de máquina para los nodos"
  type        = string
  default     = "e2-standard-2"
}

variable "image_family" {
  description = "Familia de la imagen OS (ej. ubuntu-2204-lts)"
  type        = string
  default     = "ubuntu-2204-lts"
}

variable "image_project" {
  description = "Proyecto de la imagen OS"
  type        = string
  default     = "ubuntu-os-cloud"
}
