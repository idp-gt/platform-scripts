variable "project_id" {
  description = "El ID del proyecto de GCP"
  type        = string
}

variable "region" {
  description = "La región principal donde se desplegarán los recursos"
  type        = string
}

variable "hub_network_name" {
  description = "Nombre de la VPC del Hub"
  type        = string
  default     = "vpc-hub"
}

variable "spoke_network_name" {
  description = "Nombre de la VPC de los Spokes"
  type        = string
  default     = "vpc-spokes"
}

variable "hub_subnet_cidr" {
  description = "Rango CIDR para la subred del Hub"
  type        = string
  default     = "10.0.0.0/20"
}

variable "spoke_subnet_cidr" {
  description = "Rango CIDR para la subred de los Spokes"
  type        = string
  default     = "10.1.0.0/20"
}
