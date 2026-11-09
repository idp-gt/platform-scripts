output "global_anycast_ip" {
  description = "La dirección IP pública Anycast del Load Balancer Global"
  value       = google_compute_global_address.hybrid_ip.address
}
