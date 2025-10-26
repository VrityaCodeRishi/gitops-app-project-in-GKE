locals {
  project_id   = "buoyant-episode-386713"
  region       = "us-central1"
  zones        = ["us-central1-a"]
  cluster_name = "gitops-project"
}

remote_state {
  backend = "gcs"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket = "gitops-project-tf-state"
    prefix = "gitops-demo/${path_relative_to_include()}"
  }
}
