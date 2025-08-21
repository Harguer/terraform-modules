locals {
  project_name     = "devops"
  namespace        = "devops"
  application_name = "root"
}

resource "kubernetes_manifest" "argo_devops_project" {
  count    = var.enable_argocd ? 1 : 0
  manifest = yamldecode(templatefile("${path.module}/files/argo-project.yaml", { project_name = local.project_name, namespace = local.namespace }))
  field_manager {
    name           = "terraform"
    force_conflicts = true
  }
  # depends_on = [kubernetes_manifest.ghe-external-secret]
}

resource "kubernetes_manifest" "argo_devops_application" {
  count = var.enable_argocd ? 1 : 0
  manifest = yamldecode(templatefile("${path.module}/files/argo-application.yaml", {
    project_name         = local.project_name,
    namespace            = local.namespace,
    application_name     = local.application_name,
    application_repo_url = var.root_application_repo_url,
    application_path     = var.root_application_path,
    application_branch   = var.root_application_branch,
    kubernetes_api_server = var.kubernetes_api_server
    }
  ))
  field_manager {
    name           = "terraform"
    force_conflicts = true
  }
  
  depends_on = [kubernetes_manifest.argo_devops_project]
}
