variable "cert_manager_chart_name" {
  description = "Helm chart name for cert-manager"
  type        = string
  default     = "cert-manager"
}

variable "cert_manager_repo_url" {
  description = "Helm repository URL for cert-manager"
  type        = string
  default     = "https://charts.jetstack.io"
}

variable "cert_manager_namespace" {
  description = "Namespace to deploy cert-manager"
  type        = string
  default     = "cert-manager"
}
variable "argocd_certificate_issuer_name" {
  description = "Name of the certificate issuer for ArgoCD"
  type        = string
  default     = "cert-manager-webhook-duckdns-production"
}

variable "enable_cert_manager" {
  description = "Determines whether to deploy cert-manager"
  type        = bool
  default     = true
}


variable "cert_manager_helm_version" {
  description = "cert-manager Helm version"
  type        = string
}

variable "enable_argocd" {
  description = "Determines whether to deploy ArgoCD"
  type        = bool
  default     = true
}

variable "argocd_helm_version" {
  description = "ArgoCD Helm version"
  type        = string
}

variable "argocd_domain" {
  description = "Domain to be used by ArgoCD"
  type        = string
}

variable "argo_oidc_issuer" {
  description = "ArgoCD OIDC issuer"
  type        = string
  default     = "https://ssointernal-sso-qa.vwoa.na.vwg"
}
variable "enable_istio" {
  description = "Determines whether to deploy Istio"
  type        = bool
  default     = true
}

variable "istio_helm_version" {
  description = "Istio Helm version"
  type        = string
}


variable "istio_ingress_values" {
  description = "Values for the istio ingress Helm chart"
  type        = string
}

variable "enable_metallb" {
  description = "Determines whether to deploy MetalLB"
  type        = bool
  default     = true
}

variable "metallb_helm_version" {
  description = "MetalLB Helm version"
  type        = string
}

variable "metallb_values" {
  description = "Values for the MetalLB Helm chart"
  type        = string
  default     = ""
}

variable "metallb_pool_name" {
  description = "Name of the MetalLB IPAddressPool and reference in L2Advertisement"
  type        = string
  default     = "first-pool"
}

variable "metallb_namespace" {
  description = "Namespace for MetalLB resources"
  type        = string
  default     = "metallb-system"
}

variable "metallb_pool_addresses" {
  description = "Addresses for the MetalLB IPAddressPool (comma-separated or YAML list)"
  type        = string
  default     = "10.0.0.128/25"
}

variable "metallb_l2adv_name" {
  description = "Name of the MetalLB L2Advertisement"
  type        = string
  default     = "example"
}

variable "external_secrets_helm_version" {
  description = "External Secrets Operator version"
  type        = string
  default     = ""
}


variable "enable_external_secrets" {
  description   = "Determines whether to deploy external secrets"
  type          = bool
  default       = true
}

variable "create_namespace_external_secrets" {
  description   = "Determines whether to create external-secrets namespace"
  type          = bool
  default       = true
}