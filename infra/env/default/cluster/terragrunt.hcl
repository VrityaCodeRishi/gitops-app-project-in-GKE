include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../terraform-cluster"
}

inputs = {
  project_id                 = include.root.locals.project_id
  region                     = include.root.locals.region
  zones                      = include.root.locals.zones
  cluster_name               = include.root.locals.cluster_name
  node_count                 = 2
  artifact_registry_location = include.root.locals.region
  artifact_registry_repository = "gitops-demo"
}
