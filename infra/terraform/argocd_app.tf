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

  depends_on = [helm_release.argocd]
}
