resource "helm_release" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  name = "external-secrets"

  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  version          = var.external_secrets_helm_version
  create_namespace = true
  timeout          = 600

}

