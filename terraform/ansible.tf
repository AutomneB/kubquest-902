resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_private_key" {
  content         = tls_private_key.ssh_key.private_key_openssh
  filename        = "${var.ssh_key_path}/azukey"
  file_permission = "0600"
}

resource "local_file" "ssh_public_key" {
  content  = tls_private_key.ssh_key.public_key_openssh
  filename = "${var.ssh_key_path}/azukey.pub"
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory.ini"
  content  = <<EOT

[k8s_nodes:children]
master
workers

[master]
master ansible_host=${azurerm_linux_virtual_machine.master.public_ip_address} ansible_user=${var.instance_username} ansible_ssh_private_key_file=${local_file.ssh_private_key.filename}

[workers]
%{for idx, worker in azurerm_linux_virtual_machine.worker~}
worker${idx + 1} ansible_host=${worker.public_ip_address} ansible_user=${var.instance_username} ansible_ssh_private_key_file=${local_file.ssh_private_key.filename}
%{endfor}
EOT
}

resource "local_file" "ssh_config_entry_master" {
  filename = "${pathexpand("~/.ssh/config")}"
  file_permission = "0600"

  content = <<-EOT
Host k8s-master
  HostName ${azurerm_linux_virtual_machine.master.public_ip_address}
  User ${var.instance_username}
  IdentityFile ${path.cwd}/${local_file.ssh_private_key.filename}
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
EOT

  depends_on = [local_file.ssh_private_key]
}
