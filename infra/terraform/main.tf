locals {
  argocd_image_settings = merge(
    var.argocd_image_repository != null && trimspace(var.argocd_image_repository) != "" ? {
      repository = var.argocd_image_repository
    } : {},
    var.argocd_image_tag != null && trimspace(var.argocd_image_tag) != "" ? {
      tag = var.argocd_image_tag
    } : {}
  )

  argocd_base_values = merge(
    {
      server = {
        service = {
          type = var.argocd_server_service_type
        }
      }
    },
    length(local.argocd_image_settings) > 0 ? {
      global = {
        image = local.argocd_image_settings
      }
    } : {}
  )

  argocd_values = concat(
    [
      yamlencode(local.argocd_base_values)
    ],
    var.argocd_additional_values
  )
}

resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "container" {
  project = var.project_id
  service = "container.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "images" {
  project       = var.project_id
  location      = var.artifact_registry_location
  repository_id = var.artifact_registry_repository
  format        = "DOCKER"
  description   = "Container images for the GitOps demo workloads"

  depends_on = [google_project_service.artifactregistry]
}

resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = element(var.zones, 0)

  network    = var.network
  subnetwork = var.subnetwork

  deletion_protection = false

  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = "REGULAR"
  }

  networking_mode = "VPC_NATIVE"

  ip_allocation_policy {}

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  depends_on = [
    google_project_service.compute,
    google_project_service.container,
    google_project_service.artifactregistry
  ]
}

resource "google_container_node_pool" "primary_nodes" {
  name     = "${var.cluster_name}-pool"
  cluster  = google_container_cluster.primary.name
  location = element(var.zones, 0)

  node_count = var.node_count

  node_config {
    machine_type = var.node_machine_type
    disk_size_gb = var.node_disk_size_gb
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append"
    ]
    metadata = {
      disable-legacy-endpoints = "true"
    }
    labels = {
      env = "gitops-demo"
    }
    tags = ["gitops-demo"]
  }

  node_locations = var.zones

  depends_on = [google_container_cluster.primary]
}

resource "helm_release" "argocd" {
  provider = helm.gke

  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = var.argocd_namespace
  create_namespace = true
  values           = local.argocd_values

  depends_on = [
    google_container_node_pool.primary_nodes
  ]
}
