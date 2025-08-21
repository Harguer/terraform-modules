# resource "kubernetes_manifest" "vw-custom-ca" {
#   count    = var.enable_argocd ? 1 : 0
#   manifest = yamldecode(file("${path.module}/files/vw-custom-ca.yaml"))

#   depends_on = [aws_eks_addon.addons["vpc-cni"]]
# }
resource "helm_release" "argocd" {
  count = var.enable_argocd ? 1 : 0

  name = "argocd"

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = var.argocd_helm_version
  cleanup_on_fail  = true
  wait_for_jobs    = true
  timeout          = 1000

  values = [templatefile("${path.module}/values/argocd.yaml", {
    argocd_domain = var.argocd_domain,
    argo_oidc_issuer = var.argo_oidc_issuer,
    argocd_certificate_issuer_name = var.argocd_certificate_issuer_name
  })]

  depends_on = [
    helm_release.metallb,
    kubectl_manifest.metallb_crds,
    kubectl_manifest.metallb_l2
  ]

}

output "argocd-initial-admin-secret-command" {
  value = var.enable_argocd ? "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d" : "ArgoCD is not enabled"
}

output "argocd-server-url" {
  value = var.enable_argocd ? "https://${var.argocd_domain}" : "ArgoCD is not enabled"
}
