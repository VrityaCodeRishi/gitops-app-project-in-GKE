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

variable "argocd_namespace" {
  description = "Namespace where Argo CD will be installed via Helm"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Helm chart version for Argo CD (set to null for the latest)"
  type        = string
  default     = null
}

variable "argocd_server_service_type" {
  description = "Service type for the Argo CD server component (ClusterIP, LoadBalancer, etc.)"
  type        = string
  default     = "ClusterIP"
}

variable "argocd_image_repository" {
  description = "Override for the Argo CD container image repository (leave null to use the chart default)"
  type        = string
  default     = null
}

variable "argocd_image_tag" {
  description = "Override for the Argo CD container image tag (leave null to use the chart default/latest)"
  type        = string
  default     = null
}

variable "argocd_additional_values" {
  description = "Optional list of additional YAML documents to pass as values to the Argo CD Helm chart"
  type        = list(string)
  default     = []
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

variable "gitops_repo_url" {
  description = "Git repository URL that Argo CD will track for the application"
  type        = string
}

variable "gitops_repo_revision" {
  description = "Git revision (branch, tag, commit) Argo CD should sync"
  type        = string
  default     = "main"
}
