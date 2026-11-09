output "hub_vpc_id" {
  description = "El ID de la VPC del Hub"
  value       = google_compute_network.hub_vpc.id
}

output "hub_subnet_id" {
  description = "El ID de la subred del Hub"
  value       = google_compute_subnetwork.hub_subnet.id
}

output "spokes_vpc_id" {
  description = "El ID de la VPC de los Spokes"
  value       = google_compute_network.spokes_vpc.id
}

output "spokes_subnet_id" {
  description = "El ID de la subred de los Spokes"
  value       = google_compute_subnetwork.spokes_subnet.id
}
