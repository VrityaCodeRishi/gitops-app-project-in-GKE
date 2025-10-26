resource "kubernetes_manifest" "gitops_application" {
  provider = kubernetes.gke

  manifest = yamldecode(
    templatefile(
      "${path.module}/templates/argocd-application.yaml.tmpl",
      {
        namespace       = var.argocd_namespace
        repo_url        = var.gitops_repo_url
        target_revision = var.gitops_repo_revision
      }
    )
  )

  depends_on = [time_sleep.wait_for_argocd_crds]
}

resource "kubernetes_manifest" "monitoring_application" {
  count    = var.enable_monitoring ? 1 : 0
  provider = kubernetes.gke

  manifest = yamldecode(
    templatefile(
      "${path.module}/templates/monitoring-application.yaml.tmpl",
      {
        namespace            = var.argocd_namespace
        repo_url             = var.gitops_repo_url
        target_revision      = var.gitops_repo_revision
        monitoring_namespace = var.monitoring_namespace
      }
    )
  )

  depends_on = [time_sleep.wait_for_argocd_crds]
}
