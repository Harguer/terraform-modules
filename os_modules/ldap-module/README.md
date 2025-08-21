
# OpenLDAP Restore Terraform Module

**This module is intended only for restoring an OpenLDAP server from a backup in case of disaster recovery or migration. It is not a general-purpose OpenLDAP provisioning module.**

It connects to a remote host via SSH and restores OpenLDAP configuration and data from backup files and directories.

## Features
- Installs OpenLDAP and ldap-utils packages on a remote server (Debian/Ubuntu).
- Uploads a backup LDAP configuration directory and backup LDIF files, replacing the server's `/etc/ldap` config and data.
- Restores both configuration and data using `slapadd` (see Notes below).
- Ensures correct permissions and restarts the slapd service.
- Uses a hash of the config directory to trigger redeployment when local files change.

## Usage
```
module "openldap_restore" {
  source              = "git@gitpi.davidsghome.com:harguer/terraform-modules.git//os_modules/ldap-module?ref=main"
  host                = "192.168.1.254"
  user                = "pi"
  private_key         = "/home/harguer/.ssh/id_rsa"
  ldap_config_dir     = "/path/to/etc-ldap"
  ldap_config_backup  = "/path/to/ldap-config_YYYYMMDD_HHMMSS.ldif.gz"
  ldap_data_backup    = "/path/to/ldap-data_YYYYMMDD_HHMMSS.ldif.gz"
}
```

## Requirements
- Remote host must be accessible via SSH.
- The user must have sudo privileges.
- The backup config directory and LDIF files must be complete and compatible with the target OpenLDAP version.

## Notes
- **This module is destructive:** It will delete the contents of `/etc/ldap` and `/var/lib/ldap` on the remote host before restoring from backup. Ensure your backup is complete and valid!
- The module restores both configuration and data using `slapadd` and expects compressed LDIF files as input.
- Designed for Debian/Ubuntu systems.
- Only use this module for disaster recovery or migration scenarios where a full restore is required.

## Inputs
- `host`: Remote host IP or DNS name.
- `user`: SSH user.
- `private_key`: Path to SSH private key.
- `ldap_config_dir`: Path to local backup config directory.
- `ldap_config_backup`: Path to compressed LDAP config LDIF backup file.
- `ldap_data_backup`: Path to compressed LDAP data LDIF backup file.

## Outputs
None.

## License
MIT
