output "gke-cluster" {
  description = "Deployed GKE cluster."
  value       = module.cluster
  sensitive   = true
}

output "lb" {
  description = "Application Load Balancer."
  value       = module.application-lb
  sensitive   = true
}

output "umig" {
  description = "Unmanaged instance group."
  value       = google_compute_instance_group.umig
  sensitive   = true
}

output "vm" {
  description = "Deployed VM."
  value       = module.compute-vm
  sensitive   = true
}