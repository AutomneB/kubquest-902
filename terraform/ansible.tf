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


resource "ansible_playbook" "playbook" {
  playbook = var.ansible_playbook_file
  name     = "k8s_setup"

  extra_vars = {
    ansible_ssh_private_key_file = local_file.ssh_private_key.filename
    ansible_ssh_common_args      = "-o StrictHostKeyChecking=no"
    ansible_user                 = var.instance_username
    ansible_port                 = var.ansible_port
  }

  verbosity = 1

  depends_on = [
    azurerm_linux_virtual_machine.master,
    azurerm_linux_virtual_machine.worker
  ]
}
