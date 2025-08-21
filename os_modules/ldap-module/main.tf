# 1. Install OpenLDAP packages
resource "null_resource" "install_openldap" {
  connection {
    type        = "ssh"
    host        = var.host
    user        = var.user
    private_key = file(var.private_key)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      # Pre-seed debconf to avoid interactive prompts during installation.
      # These values are temporary and will be overwritten by your backup.
      "echo 'slapd slapd/domain string example.com' | sudo debconf-set-selections",
      "echo 'slapd slapd/password_hash string' | sudo debconf-set-selections",
      "echo 'slapd slapd/root_password string' | sudo debconf-set-selections",
      "echo 'slapd slapd/root_password_again string' | sudo debconf-set-selections",
      # Install the packages non-interactively
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y slapd ldap-utils",
      "sudo chown -R openldap:openldap /etc/ldap/",
      "sudo systemctl enable slapd"
    ]
  }
}

# 2. Deploy configuration from your backup
resource "null_resource" "deploy_ldap_config" {
  depends_on = [null_resource.install_openldap]

  connection {
    type        = "ssh"
    host        = var.host
    user        = var.user
    private_key = file(var.private_key)
  }

  # Upload the entire config directory to a temporary location
  provisioner "file" {
    source      = var.ldap_config_dir
    destination = "/tmp/ldap_config"
  }

  # Upload backup script and crontab
  provisioner "file" {
    source      = "${var.ldap_config_dir}/ldap_full_backup.sh"
    destination = "/tmp/ldap_full_backup.sh"
  }
  provisioner "file" {
    source      = "${var.ldap_config_dir}/crontab"
    destination = "/tmp/ldap_full_backup_crontab"
  }

  # Stop slapd, replace the configuration, and restart
  provisioner "remote-exec" {
    inline = [
      "set -e",
      "sudo mkdir -p /mnt/ldap-backups",
      "sudo chmod 1777 /mnt/ldap-backups",
      # Move backup script and crontab into place
      "sudo mv /tmp/ldap_full_backup.sh /usr/local/sbin/ldap_full_backup.sh",
      "sudo chmod +x /usr/local/sbin/ldap_full_backup.sh",
      "sudo mv /tmp/ldap_full_backup_crontab /etc/cron.d/ldap_full_backup",
      "sudo systemctl stop slapd",
      # Move your backed-up configuration into place
      "sudo mv /tmp/ldap_config/* /etc/ldap/",
      "sudo rm -rf /tmp/ldap_config",
      # Set correct ownership and permissions for config and data directories
      "sudo chown -R openldap:openldap /etc/ldap/",
      "sudo chown -R openldap:openldap /var/lib/ldap",
      # Uncompress backup files into /etc/ldap/ for reference
      "if ls /etc/ldap/ldap-config_*.ldif.gz 1> /dev/null 2>&1; then sudo gzip -dc /etc/ldap/ldap-config_*.ldif.gz | sudo tee /etc/ldap/ldap-config.ldif > /dev/null; fi",
      "if ls /etc/ldap/ldap-data_*.ldif.gz 1> /dev/null 2>&1; then sudo gzip -dc /etc/ldap/ldap-data_*.ldif.gz | sudo tee /etc/ldap/ldap-data.ldif > /dev/null; fi",
      # Import config and data using slapadd, log output for debugging
      "sudo mv /var/lib/ldap /var/lib/ldap.bak.$(date +%s) || true",
      "sudo mkdir -p /var/lib/ldap",
      "sudo chown openldap:openldap /var/lib/ldap",
      "sudo chmod 700 /var/lib/ldap",
      # Clear slapd.d config directory before import
      "sudo rm -rf /etc/ldap/slapd.d/*",
      # Import config (slapd must be stopped)
      "if [ -f /etc/ldap/ldap-config.ldif ]; then sudo slapadd -v -n 0 -F /etc/ldap/slapd.d -l /etc/ldap/ldap-config.ldif | tee /tmp/slapadd-config.log; fi",
      # Import data
      "if [ -f /etc/ldap/ldap-data.ldif ]; then sudo slapadd -v -n 1 -F /etc/ldap/slapd.d -l /etc/ldap/ldap-data.ldif | tee /tmp/slapadd-data.log; fi",
      # Fix permissions
      "sudo chown -R openldap:openldap /var/lib/ldap /etc/ldap/",
      # Reconfigure the package to ensure everything is set up correctly with the new config
      #"sudo dpkg-reconfigure -f noninteractive slapd",
      # Start the service to apply changes
      "sudo systemctl start slapd",
      "sudo systemctl status slapd --no-pager || sudo journalctl -u slapd -e --no-pager"
    ]
  }

  # This trigger ensures that if any file in your local config directory changes,
  # Terraform will re-run the deployment.
  triggers = {
    config_hash = sha256(join("", [
      for f in fileset(var.ldap_config_dir, "**/*") : filesha256("${var.ldap_config_dir}/${f}")
    ]))
  }
}


