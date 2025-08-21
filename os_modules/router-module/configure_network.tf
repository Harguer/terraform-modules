locals {
  # Grab exactly the two files we care about
  sysctl_files = [
    "99-ip-forward.conf",
    "99-disable-ipv6.conf",
  ]

  # Hash them so Terraform will re‑run when any change
  sysctl_hash = sha256(
    join("", [
      for f in local.sysctl_files :
      filesha256("${var.sysctl_dir}/${f}")
    ])
  )
}

resource "null_resource" "configure_network" {
  triggers = {
    config_hash = local.sysctl_hash
  }

  connection {
    type        = "ssh"
    host        = var.host
    user        = var.user
    private_key = file(var.private_key)
  }

  provisioner "file" {
    source      = "${var.sysctl_dir}/99-disable-ipv6.conf"
    destination = "/tmp/99-disable-ipv6.conf"
  }

  # upload into /tmp so we can sudo‑move it
  provisioner "file" {
    source      = "${var.sysctl_dir}/99-ip-forward.conf"
    destination = "/tmp/99-ip-forward.conf"
  }


  # Apply & enable
  provisioner "remote-exec" {
    inline = [
      # move into place with root perms
      "sudo mv /tmp/99-ip-forward.conf /etc/sysctl.d/99-ip-forward.conf",
      "sudo mv /tmp/99-disable-ipv6.conf /etc/sysctl.d/99-disable-ipv6.conf",
      "sudo sysctl --system",
      "sudo systemctl enable systemd-sysctl.service",
    ]
  }
}

