variable "sysctl_dir" {
  description = "Path to a directory containing .conf files to drop into /etc/sysctl.d/"
  type        = string
}

variable "host" {
  description = "Router hostname/IP"
  type        = string
}

variable "user" {
  description = "SSH username"
  type        = string
  default     = "admin"
}

variable "private_key" {
  description = "SSH private key path"
  type        = string
}

variable "iptables_rules" {
  description = "Path to iptables rules.v4 file"
  type        = string
  default     = ""
}
