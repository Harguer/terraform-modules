# 1) Install & enable the persistence framework
resource "null_resource" "install_iptables_persistent" {
  depends_on = [null_resource.configure_network]

  connection {
    type        = "ssh"
    host        = var.host
    user        = var.user
    private_key = file(var.private_key)
  }

  provisioner "remote-exec" {
    inline = [
      # ensure apt metadata is fresh
      "sudo apt-get update -y",

      # preseed so it won’t prompt you to save rules on install
      "echo 'iptables-persistent iptables-persistent/autosave_v4 boolean true' | sudo debconf-set-selections",
      "echo 'iptables-persistent iptables-persistent/autosave_v6 boolean false' | sudo debconf-set-selections",

      # install the package (provides iptables-save, iptables-restore,
      # and a systemd service that picks up /etc/iptables/rules.v4 on boot)
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent",

      # make sure the netfilter‑persistent service is enabled at boot
      "sudo systemctl enable netfilter-persistent.service",
    ]
  }
}

# 2) Copy your rules and load them now
resource "null_resource" "deploy_iptables" {
  count = var.iptables_rules != "" ? 1 : 0

  depends_on = [
    null_resource.configure_network,
    null_resource.install_iptables_persistent,
  ]

  connection {
    type        = "ssh"
    host        = var.host
    user        = var.user
    private_key = file(var.private_key)
  }

  provisioner "file" {
    source      = var.iptables_rules
    destination = "/tmp/rules.v4"
  }


  # Force this resource to recreate whenever the local rules file changes
  triggers = {
    rules_hash = filesha256(var.iptables_rules)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/iptables",
      "sudo mv /tmp/rules.v4 /etc/iptables/rules.v4",

      # load them immediately
      "sudo iptables-restore < /etc/iptables/rules.v4",

      # and save the IPTABLES state so iptables-persistent really has
      # the correct file on disk (should be a no-op, but safe):
      "sudo netfilter-persistent save",
    ]
  }
}

