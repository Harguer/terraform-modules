variable "ldap_config_backup" {
  description = "Path to the compressed LDAP config LDIF backup file (e.g., ldap-config_*.ldif.gz)"
  type        = string
}

variable "ldap_data_backup" {
  description = "Path to the compressed LDAP data LDIF backup file (e.g., ldap-data_*.ldif.gz)"
  type        = string
}
variable "host" {
  description = "The hostname or IP address of the target server."
  type        = string
}

variable "user" {
  description = "The SSH user to connect to the server."
  type        = string
}

variable "private_key" {
  description = "The path to the SSH private key."
  type        = string
}

variable "ldap_config_dir" {
  description = "Path to the local directory containing the OpenLDAP configuration files (contents of /etc/ldap)."
  type        = string
}

