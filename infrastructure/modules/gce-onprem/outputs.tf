output "api_server_vip" {
  description = "Virtual IP (VIP) del API Server de Kubernetes (L4 Load Balancer)"
  value       = google_compute_forwarding_rule.api_vip.ip_address
}

output "master_ips" {
  description = "IPs privadas de los nodos Master"
  value       = [for inst in google_compute_instance.master : inst.network_interface[0].network_ip]
}

output "worker_ips" {
  description = "IPs privadas de los nodos Worker"
  value       = [for inst in google_compute_instance.worker : inst.network_interface[0].network_ip]
}

output "worker_instance_group_id" {
  description = "ID del Instance Group de workers"
  value       = google_compute_instance_group.worker_group.id
}
