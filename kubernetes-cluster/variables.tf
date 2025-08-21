variable "kubernetes_version" {
  description = "Kubernetes version to install (e.g., 1.30.5-1.1)"
  type        = string
  default     = "1.30.5-1.1"
}

variable "crio_version" {
  description = "CRI-O version to install (e.g., 1.30)"
  type        = string
  default     = "1.30"
}

variable "os_name" {
  description = "OS name for CRI-O repo (e.g., Debian_12)"
  type        = string
  default     = "Debian_12"
}
variable "nodes" {
  description = "List of nodes to be configured"
  type = list(object({
    node_ip              = string
    ssh_private_key_path = string
    ssh_user             = string  # Add ssh_user here
  }))
}

variable "ssh_user" {
  description = "SSH user for the Raspberry Pi node"
  type        = string
}

variable "control_plane_ip" {
  description = "IP or hostname of the control plane"
  type        = string
}


variable "ssh_private_key_path" {
  description = "Path to the SSH private key used for the nodes and control plane"
  type        = string
}

variable "control_plane_user" {
  description = "SSH user for the control plane"
}

variable "control_plane_private_key_path" {
  description = "Path to the SSH private key for the control plane"
}

