resource "null_resource" "install_k8s_components" {
  for_each = { for idx, node in var.nodes : idx => node }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update && sudo apt install -y apt-transport-https ca-certificates curl gpg",
      "[ ! -d /etc/apt/keyrings ] && sudo mkdir -p -m 755 /etc/apt/keyrings",
      "[ -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg ] && (echo file exist, removing && sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg)",
      "curl -fsSL https://pkgs.k8s.io/core:/stable:/v${var.crio_version}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${var.crio_version}/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list",
      "sudo apt-mark unhold kubelet kubeadm kubectl",
      "sudo apt update && sudo apt install -y kubelet=${var.kubernetes_version} kubeadm=${var.kubernetes_version} kubectl=${var.kubernetes_version}",
      "sudo apt-mark hold kubelet kubeadm kubectl",
      "sudo swapoff -a", 
      "sudo dphys-swapfile swapoff",
      "echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf",
      "sudo sysctl -p"
    ]

    connection {
      type        = "ssh"
      user        = each.value.ssh_user
      host        = each.value.node_ip
      private_key = file(each.value.ssh_private_key_path)
    }
  }
}

resource "null_resource" "install_crio" {
  for_each = { for idx, node in var.nodes : idx => node }

  provisioner "remote-exec" {
    inline = [
      # Set up OS and Kubernetes version
      "export OS=${var.os_name}",
      "export VERSION=${var.crio_version}",

      # Add the CRI-O repository and key
      "sudo rm -fv /etc/apt/keyrings/cri-o-apt-keyring.gpg",
      "echo \"deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/stable:/v${var.crio_version}/deb/ /\" | sudo tee /etc/apt/sources.list.d/cri-o.list",
      "curl -L https://pkgs.k8s.io/addons:/cri-o:/stable:/v${var.crio_version}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg",

      # Update the package list and install CRI-O
      "sudo apt update",
      "sudo apt install -y cri-o",

      # Enable and start CRI-O
      "sudo systemctl enable crio --now"
    ]

    connection {
      type        = "ssh"
      user        = each.value.ssh_user
      host        = each.value.node_ip
      private_key = file(each.value.ssh_private_key_path)
    }
  }
}


resource "null_resource" "update_cmdline_txt" {
  for_each = { for idx, node in var.nodes : idx => node }

  provisioner "remote-exec" {
    inline = [
      # Check and update cgroup settings in /boot/firmware/cmdline.txt if missing
      "grep -q 'cgroup_enable=memory' /boot/firmware/cmdline.txt || sudo sed -i \"s/$/ cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1/\" /boot/firmware/cmdline.txt && touch /tmp/no_reboot",
      "cat /boot/firmware/cmdline.txt"
    ]

    connection {
      type        = "ssh"
      user        = each.value.ssh_user
      host        = each.value.node_ip
      private_key = file(each.value.ssh_private_key_path)
    }
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}

# Resource to reboot if necessary
resource "null_resource" "reboot_node" {
  for_each = { for idx, node in var.nodes : idx => node }

  provisioner "remote-exec" {
    inline = [
      "[ -f i/tmp/no_reboot ] && sudo reboot || echo no need to reboot"
    ]

    connection {
      type        = "ssh"
      user        = each.value.ssh_user
      host        = each.value.node_ip
      private_key = file(each.value.ssh_private_key_path)
    }

    # Optional: Continue even if reboot fails
    on_failure = continue
  }

  depends_on = [null_resource.update_cmdline_txt]
}

resource "null_resource" "wait_for_reboot" {
  for_each = { for idx, node in var.nodes : idx => node }

  provisioner "remote-exec" {
    inline = [
      "sleep 10",
      "until ping -c1 ${each.value.node_ip} &>/dev/null; do sleep 1; done",
      "echo 'Reboot successful!'"
    ]
  }

  connection {
    type        = "ssh"
    user        = each.value.ssh_user
    host        = each.value.node_ip
    private_key = file(each.value.ssh_private_key_path)
  }

  depends_on = [null_resource.update_cmdline_txt]
}



resource "null_resource" "generate_kubeadm_join_info" {
  provisioner "remote-exec" {
    inline = [
      "kubeadm token create",
      "openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'"
    ]

    connection {
      type        = "ssh"
      user        = var.control_plane_user
      host        = var.control_plane_ip
      private_key = file(var.control_plane_private_key_path)
    }

    # Capture the command output
    on_failure = continue
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}

resource "null_resource" "kubeadm_join_node" {
  for_each = { for idx, node in var.nodes : idx => node }
  depends_on = [null_resource.install_k8s_components, null_resource.install_crio, null_resource.generate_kubeadm_join_info, null_resource.wait_for_reboot]

  provisioner "remote-exec" {
    inline = [
      "set -x",
      "sudo swapoff -a",
      "echo reset any previous kubeadm config ",
      "sudo kubeadm reset --force",
      "sudo rm -rf /etc/kubernetes/*",
      "TOKEN=$(ssh k8-pi-master1 \"sudo kubeadm token create\")", 
      "CERT=sha256:$(ssh k8-pi-master1 \"openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed \\\"s/^.* //\\\"\")",
      #"sudo kubeadm join ${var.control_plane_ip}:6443 --token $TOKEN --discovery-token-ca-cert-hash $CERT"
      "echo STARTING KUBEADM JOIN",
      "if [ ! -f /var/lock/kubeadm_join.lock ]; then touch /var/lock/kubeadm_join.lock; echo running kubeadm;sudo kubeadm join ${var.control_plane_ip}:6443 --token $TOKEN --discovery-token-ca-cert-hash $CERT; rm /var/lock/kubeadm_join.lock; else echo 'Another kubeadm join is running'; fi"
    ]
    connection {
      type        = "ssh"
      user        = each.value.ssh_user
      host        = each.value.node_ip
      private_key = file(each.value.ssh_private_key_path)
    }
  }
}

