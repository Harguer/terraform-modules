resource "null_resource" "install_dnscrypt" {
  count = var.dnscrypt_config_file != "" ? 1 : 0

  connection {
    type        = "ssh"
    host        = var.host
    user        = var.user
    private_key = file(var.private_key)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update || true",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing -o Dpkg::Options::=\"--force-confold\" dnscrypt-proxy || sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -o Dpkg::Options::=\"--force-confold\" dnscrypt-proxy",
      "sudo systemctl restart systemd-resolved || true"
    ]
  }
}

resource "null_resource" "deploy_dnscrypt_config" {
  count = var.dnscrypt_config_file != "" ? 1 : 0
  depends_on = [
    null_resource.install_dnscrypt,
    null_resource.install_bind,
    null_resource.restart_bind
  ]

  connection {
    type        = "ssh"
    host        = var.host
    user        = var.user
    private_key = file(var.private_key)
  }

  provisioner "file" {
    source      = var.dnscrypt_config_file
    destination = "/tmp/dnscrypt-proxy.toml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/dnscrypt-proxy",
      "sudo mv /tmp/dnscrypt-proxy.toml /etc/dnscrypt-proxy/",
      "sudo chown root:root /etc/dnscrypt-proxy/dnscrypt-proxy.toml",
      "sudo chmod 644 /etc/dnscrypt-proxy/dnscrypt-proxy.toml",
      "if systemctl list-unit-files | grep -q dnscrypt-proxy.service; then",
      "  sudo systemctl restart dnscrypt-proxy",
      "else",
      "  sudo systemctl enable --now dnscrypt-proxy || true",
      "fi"
    ]
  }
}

resource "null_resource" "install_bind" {
  connection {
    type        = "ssh"
    host        = var.host
    user        = var.user
    private_key = file(var.private_key)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update || true",
      "sudo apt-get install -y --fix-missing bind9 bind9utils || sudo apt-get install -y bind9 bind9utils",
      "sudo systemctl restart systemd-resolved || true"
    ]
  }
}

resource "null_resource" "deploy_configs" {
  depends_on = [null_resource.install_bind]

  connection {
    type        = "ssh"
    host        = var.host
    user        = var.user
    private_key = file(var.private_key)
  }

  provisioner "file" {
    source      = "${var.bind_config_dir}/named.conf"
    destination = "/tmp/named.conf"
  }

  provisioner "file" {
    source      = "${var.bind_config_dir}/named.conf.local"
    destination = "/tmp/named.conf.local"
  }

  provisioner "file" {
    source      = "${var.bind_config_dir}/named.conf.options"
    destination = "/tmp/named.conf.options"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/named.conf /etc/bind/",
      "sudo mv /tmp/named.conf.local /etc/bind/",
      "sudo mv /tmp/named.conf.options /etc/bind/"
    ]
  }
}


resource "null_resource" "deploy_zones" {
  depends_on = [
    null_resource.install_bind,
    null_resource.deploy_configs,    # make sure your named.conf* are in place first
  ]

  connection {
    type        = "ssh"
    host        = var.host
    user        = var.user
    private_key = file(var.private_key)
  }

  # 1) copy your entire local bind_config_dir up to /tmp/bind_zones
  provisioner "file" {
    source      = "${path.module}/${var.bind_config_dir}"
    destination = "/tmp/bind_zones"
  }

  # 2) on the remote, move only your zone files + TSIG key into /etc/bind
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/bind",
      # this will match any file starting with db* OR named tsig.key
      "sudo find /tmp/bind_zones -maxdepth 1 -type f \\( -name 'db*' -o -name 'tsig.key' \\) -exec mv {} /etc/bind/ \\;",
      "sudo rm -rf /tmp/bind_zones",
    ]
  }
}


resource "null_resource" "set_permissions" {
  depends_on = [
    null_resource.deploy_configs,
    null_resource.deploy_zones
  ]

  connection {
    type        = "ssh"
    host        = var.host
    user        = var.user
    private_key = file(var.private_key)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chown -R bind:bind /etc/bind",
      "sudo chmod -R 640 /etc/bind/*"
    ]
  }
}

resource "null_resource" "restart_bind" {
  depends_on = [null_resource.set_permissions]

  connection {
    type        = "ssh"
    host        = var.host
    user        = var.user
    private_key = file(var.private_key)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo named-checkconf /etc/bind/named.conf",
      "sudo systemctl daemon-reload",
      "sudo systemctl restart named",
      "sudo systemctl status named --no-pager || sudo journalctl -xe -u named --no-pager"
    ]
  }
}

resource "null_resource" "verify_dnscrypt" {
  count = var.dnscrypt_config_file != "" ? 1 : 0
  depends_on = [null_resource.deploy_dnscrypt_config]

  connection {
    type        = "ssh"
    host        = var.host
    user        = var.user
    private_key = file(var.private_key)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chown -R root:root /etc/dnscrypt-proxy",
      "sudo chmod 644 /etc/dnscrypt-proxy/dnscrypt-proxy.toml",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable dnscrypt-proxy",
      "sudo systemctl start dnscrypt-proxy",
      "sudo systemctl status dnscrypt-proxy  --no-pager || sudo journalctl -xe -u dnscrypt-proxy  --no-pager"
    ]
  }
}


###  to reload in case new changes:
locals {
  # 1) Define exactly which files to track (zones, named.conf*, tsig.key, etc)
  patterns = [
    "db*",          # all your zone files
    "named.conf*",  # named.conf, named.conf.local, options, etc
    "tsig.key"      # your TSIG secret
  ]

  # 2) Gather only those filenames
  bind_files = flatten([
    for p in local.patterns :
    fileset("${path.module}/${var.bind_config_dir}", p)
  ])

  # 3) Hash each one (binary‑safe) and combine
  bind_hash = sha256(
    join("", [
      for f in local.bind_files :
      filesha256("${path.module}/${var.bind_config_dir}/${f}")
    ])
  )
}

resource "null_resource" "reload_bind" {
  # Terraform will recreate this every time any tracked file’s hash changes
  triggers = {
    config_hash = local.bind_hash
  }

  depends_on = [ null_resource.install_bind ]

  connection {
    type        = "ssh"
    host        = var.host
    user        = var.user
    private_key = file(var.private_key)
  }

  provisioner "file" {
    source      = "${path.module}/${var.bind_config_dir}"
    destination = "/tmp/bind_zones"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/bind",
      "sudo mv /tmp/bind_zones/* /etc/bind/",
      "sudo rm -rf /tmp/bind_zones",
      "sudo chown -R bind:bind /etc/bind",
      "sudo chmod -R 640 /etc/bind/*",
      "sudo named-checkconf /etc/bind/named.conf",
      "sudo systemctl daemon-reload",
      "sudo systemctl restart named",
    ]
  }
}

