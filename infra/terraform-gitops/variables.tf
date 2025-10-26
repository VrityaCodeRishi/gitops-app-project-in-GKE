variable "project_id" {
  description = "GCP project ID hosting the cluster"
  type        = string
}

variable "region" {
  description = "Default region for the Google provider"
  type        = string
}

variable "cluster_location" {
  description = "Zone or region of the GKE cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint of the GKE control plane"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "Base64-encoded CA certificate for the GKE cluster"
  type        = string
}

variable "argocd_namespace" {
  description = "Namespace where Argo CD is installed"
  type        = string
  default     = "argocd"
}

variable "gitops_repo_url" {
  description = "Git repository URL tracked by Argo CD"
  type        = string
  default     = "https://github.com/VrityaCodeRishi/gitops-app-project-in-GKE.git"
}

variable "gitops_repo_revision" {
  description = "Git revision Argo CD should sync"
  type        = string
  default     = "main"
}

variable "monitoring_namespace" {
  description = "Namespace for the monitoring stack"
  type        = string
  default     = "monitoring"
}

variable "enable_monitoring" {
  description = "Whether to deploy the monitoring stack"
  type        = bool
  default     = true
}
