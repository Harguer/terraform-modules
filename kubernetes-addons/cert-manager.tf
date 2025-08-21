resource "helm_release" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  name             = var.cert_manager_chart_name
  repository       = var.cert_manager_repo_url
  chart            = var.cert_manager_chart_name
  namespace        = var.cert_manager_namespace
  version          = var.cert_manager_helm_version
  create_namespace = true
  timeout          = 600
  #values = [
  #  templatefile("${path.module}/values/cert-manager.yaml", { role_arn = local.cert_manager_role_arn })
  #]
}

