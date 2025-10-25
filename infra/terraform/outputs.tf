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
