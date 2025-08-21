variable "bind_config_dir" {
  description = "Path to source bind configuration files"
  type        = string
}

variable "host" {
  description = "Raspberry Pi hostname/IP"
  type        = string
}

variable "user" {
  description = "SSH username (pi)"
  type        = string
  default     = "pi" # Default Raspberry Pi user with sudo privileges
}

variable "private_key" {
  description = "SSH private key path"
  type        = string
}

variable "dnscrypt_config_file" {
  description = "Path to dnscrypt-proxy.toml config file"
  type        = string
  default     = ""
}
