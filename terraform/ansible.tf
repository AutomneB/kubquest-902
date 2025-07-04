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
masters
workers

[masters]
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

resource "local_file" "run_playbook" {
  filename = "${path.module}/run-playbook.sh"
  content  = <<-EOT
    #!/bin/sh

    #Playbook nodes
    ansible-playbook -i inventory.ini ../ansible/templates/playbook-kubernetes-basic.yml --ssh-extra-args='-o StrictHostKeyChecking=no'


    #playbook Master
    ansible-playbook -i inventory.ini ../ansible/templates/playbook-master-node.yml --ssh-extra-args='-o StrictHostKeyChecking=no'


    #playbook Worker
    ansible-playbook -i inventory.ini ../ansible/templates/playbook-worker-node.yml --ssh-extra-args='-o StrictHostKeyChecking=no'


    #Deploy application
    ansible-playbook -i inventory.ini ../ansible/templates/playbook-argocd-deploy.yml --ssh-extra-args='-o StrictHostKeyChecking=no'

    # Deploy Prometheus
    ansible-playbook -i inventory.ini ../ansible/templates/playbook-prometheus-deploy.yml --ssh-extra-args='-o StrictHostKeyChecking=no'

  EOT
  file_permission = "0755"
}
