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

variable "enable_external_secrets" {
  description = "Determines whether to deploy External Secrets"
  type        = bool
  default     = true
}

variable "enable_argocd" {
  description = "Determines whether to deploy ArgoCD"
  type        = bool
}

variable "argocd_namespace" {
  description = "ArgoCD namespace"
  type        = string
  default     = "argocd"
}

variable "root_application_repo_url" {
  description = "Argo CD root application repo URL"
  type        = string
}

variable "root_application_path" {
  description = "Argo CD root application path"
  type        = string
}

variable "root_application_branch" {
  description = "Argo CD root application branch"
  type        = string
  default     = "HEAD"
}

variable "ghe_argo_username" {
  description = "GHE username for ArgoCD"
  type        = string
  default     = "cld-argocd-mlops"
}

variable "kubernetes_api_server" {
  description = "Kubernetes API server URL"
  type        = string
  default     = "https://kubernetes.default.svc"
}

