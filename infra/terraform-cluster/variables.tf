variable "project_id" {
  description = "GCP project ID where the GKE cluster will be created"
  type        = string
}

variable "region" {
  description = "GCP region for the GKE cluster"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "gitops-demo"
}

variable "network" {
  description = "VPC network to deploy the cluster into"
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "Subnetwork to deploy the cluster into"
  type        = string
  default     = "default"
}

variable "kubernetes_version" {
  description = "GKE control plane version"
  type        = string
  default     = "1.29.4-gke.1042000"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 1
}

variable "node_machine_type" {
  description = "Machine type for worker nodes"
  type        = string
  default     = "e2-standard-4"
}

variable "node_disk_size_gb" {
  description = "Disk size for worker nodes"
  type        = number
  default     = 50
}

variable "zones" {
  description = "List of zones for the GKE cluster nodes"
  type        = list(string)
  default     = ["us-central1-a"]
}

variable "artifact_registry_location" {
  description = "Location (region) for the Artifact Registry repository"
  type        = string
  default     = "us-central1"
}

variable "artifact_registry_repository" {
  description = "Name of the Artifact Registry repository that will host container images"
  type        = string
  default     = "gitops-demo"
}
