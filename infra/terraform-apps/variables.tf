variable "project_id" {
  description = "GCP project ID hosting the cluster"
  type        = string
}

variable "region" {
  description = "Default region for Google provider"
  type        = string
}

variable "cluster_location" {
  description = "Zone or region of the GKE cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint of the GKE cluster"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "Base64-encoded CA certificate for the GKE cluster"
  type        = string
}

variable "argocd_namespace" {
  description = "Namespace where Argo CD will be installed"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Version of the Argo CD Helm chart"
  type        = string
  default     = null
}

variable "argocd_server_service_type" {
  description = "Service type for the Argo CD server"
  type        = string
  default     = "ClusterIP"
}

variable "argocd_image_repository" {
  description = "Override Argo CD image repository"
  type        = string
  default     = null
}

variable "argocd_image_tag" {
  description = "Override Argo CD image tag"
  type        = string
  default     = null
}

variable "argocd_additional_values" {
  description = "Extra Helm values for the Argo CD release"
  type        = list(string)
  default     = []
}
