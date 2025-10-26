include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "cluster" {
  config_path = "../cluster"
}

terraform {
  source = "../../../terraform-apps"
}

inputs = {
  project_id              = include.root.locals.project_id
  region                  = include.root.locals.region
  cluster_location        = dependency.cluster.outputs.cluster_location
  cluster_endpoint        = dependency.cluster.outputs.cluster_endpoint
  cluster_ca_certificate  = dependency.cluster.outputs.cluster_ca_certificate
  argocd_namespace        = "argocd"
  argocd_chart_version    = null
  argocd_server_service_type = "ClusterIP"
  argocd_image_repository = null
  argocd_image_tag        = null
  argocd_additional_values = []
}
