include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "cluster" {
  config_path = "../cluster"
}

dependencies {
  paths = ["../apps"]
}

terraform {
  source = "../../../terraform-gitops"
}

inputs = {
  project_id             = include.root.locals.project_id
  region                 = include.root.locals.region
  cluster_location       = dependency.cluster.outputs.cluster_location
  cluster_endpoint       = dependency.cluster.outputs.cluster_endpoint
  cluster_ca_certificate = dependency.cluster.outputs.cluster_ca_certificate
  argocd_namespace       = "argocd"
  gitops_repo_url        = "https://github.com/VrityaCodeRishi/gitops-app-project-in-GKE.git"
  gitops_repo_revision   = "main"
  monitoring_namespace   = "monitoring"
  enable_monitoring      = true
}
