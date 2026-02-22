output "cluster_name" {
  description = "GKE Autopilot cluster name"
  value       = google_container_cluster.autopilot.name
}

output "cluster_id" {
  description = "Cluster ID"
  value       = google_container_cluster.autopilot.id
}

output "cluster_endpoint" {
  description = "Cluster API endpoint"
  value       = google_container_cluster.autopilot.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate (base64)"
  value       = google_container_cluster.autopilot.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "location" {
  description = "Cluster location (region)"
  value       = google_container_cluster.autopilot.location
}

output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.autopilot.name} --region ${google_container_cluster.autopilot.location} --project ${var.project_id}"
}
