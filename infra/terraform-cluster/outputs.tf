output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "kubeconfig" {
  description = "Command to fetch kubeconfig for the cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${element(var.zones, 0)} --project ${var.project_id}"
}

output "artifact_registry_repository" {
  description = "Artifact Registry repository URL for pushing container images"
  value       = "${google_artifact_registry_repository.images.location}-docker.pkg.dev/${google_artifact_registry_repository.images.project}/${google_artifact_registry_repository.images.repository_id}"
}

output "cluster_endpoint" {
  description = "Endpoint of the GKE control plane"
  value       = google_container_cluster.primary.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64-encoded cluster CA certificate"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
}

output "cluster_location" {
  description = "Location (zone) of the GKE cluster"
  value       = element(var.zones, 0)
}

output "project_id" {
  description = "GCP project id"
  value       = var.project_id
}

output "region" {
  description = "Region used for the cluster"
  value       = var.region
}
