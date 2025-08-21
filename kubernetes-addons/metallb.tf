resource "null_resource" "wait_for_metallb_namespace" {
  count     = var.enable_metallb ? 1 : 0
  depends_on = [kubernetes_namespace.metallb_system]

  provisioner "local-exec" {
    command = "kubectl get ns metallb-system"
  }
}
locals {
  metallb_chart_url = "https://metallb.github.io/metallb"
}

resource "kubernetes_namespace" "metallb_system" {
  count     = var.enable_metallb ? 1 : 0
  metadata {
    name = "metallb-system"
    labels = {
      managed-by = "terraform"
    }
  }

  #lifecycle {
  #  ignore_changes = [
  #    metadata[0].annotations,
  #    metadata[0].labels,
  #  ]
  #}
}

resource "kubectl_manifest" "metallb_crds" {
  count     = var.enable_metallb ? 1 : 0
  yaml_body = yamlencode({
    apiVersion = "metallb.io/v1beta1"
    kind       = "IPAddressPool"
    metadata = {
      name      = var.metallb_pool_name
      namespace = var.metallb_namespace
    }
    spec = {
      addresses = split(",", var.metallb_pool_addresses)
    }
  })

  server_side_apply = true
  force_conflicts   = true

  depends_on = [
    kubernetes_namespace.metallb_system[0]
  ]
}

resource "kubectl_manifest" "metallb_l2" {
  count     = var.enable_metallb ? 1 : 0
  yaml_body = yamlencode({
    apiVersion = "metallb.io/v1beta1"
    kind       = "L2Advertisement"
    metadata = {
      name      = var.metallb_l2adv_name
      namespace = var.metallb_namespace
    }
    spec = {
      ipAddressPools = [var.metallb_pool_name]
    }
  })

  server_side_apply = true
  force_conflicts   = true

  depends_on = [
    kubectl_manifest.metallb_crds[0]
  ]
}

resource "helm_release" "metallb" {
  count      = var.enable_metallb ? 1 : 0
  repository = local.metallb_chart_url
  chart      = "metallb"
  name       = "metallb"
  namespace  = kubernetes_namespace.metallb_system[count.index].metadata[0].name
  version    = var.metallb_helm_version

  force_update  = true
  recreate_pods = true

  depends_on = [
    kubernetes_namespace.metallb_system
  ]
}
