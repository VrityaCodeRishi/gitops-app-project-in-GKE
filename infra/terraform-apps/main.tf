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

resource "null_resource" "cluster_ready" {
  triggers = {
    endpoint = var.cluster_endpoint
  }
}

resource "time_sleep" "wait_for_cluster" {
  depends_on      = [null_resource.cluster_ready]
  create_duration = "30s"
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

  depends_on = [time_sleep.wait_for_cluster]
}

resource "time_sleep" "wait_for_argocd_crds" {
  depends_on      = [helm_release.argocd]
  create_duration = "120s"
}
