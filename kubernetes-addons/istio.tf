# helm repo add istio https://istio-release.storage.googleapis.com/charts
# helm repo update
# helm install my-istio-base-release -n istio-system --create-namespace istio/base --set global.istioNamespace=istio-system
locals {
  istio_chart_url     = "https://istio-release.storage.googleapis.com/charts"
  #istio_chart_version = "1.20"
}


resource "kubernetes_namespace" "istio-system" {
  metadata {
    name = "istio-system"
  }
}


resource "helm_release" "istio-base" {
  count = var.enable_istio ? 1 : 0
  repository       = local.istio_chart_url
  chart            = "base"
  name             = "istio-base"
  namespace        = kubernetes_namespace.istio-system.metadata.0.name
  version          = var.istio_helm_version
  create_namespace = true

  depends_on = [
    helm_release.metallb,
    kubectl_manifest.metallb_l2
  ]
}

resource "helm_release" "istiod" {
  count = var.enable_istio ? 1 : 0
  name       = "istiod"
  namespace  = kubernetes_namespace.istio-system.metadata.0.name
  repository = local.istio_chart_url
  chart      = "istiod"
  version          = var.istio_helm_version

  #values = [var.istiod_values]

  set {
      name  = "meshConfig.accessLogFile"
      value = "/dev/stdout"
  }

  depends_on = [helm_release.istio-base]
}


#Istio Ingress Gateway Service
resource "helm_release" "istio-ingress"{
  count = var.enable_istio ? 1 : 0
  chart            = "gateway"
  version          = var.istio_helm_version
  repository       = local.istio_chart_url
  name             = "istio-ingress"
  namespace        = "istio-ingress" # per https://github.com/istio/istio/blob/master/manifests/charts/gateways/istio-ingress/values.yaml#L2
  create_namespace = true
  #values           = [var.istio_ingress_values]
  depends_on = [
    helm_release.istio-base,
    helm_release.istiod
  ]
}

