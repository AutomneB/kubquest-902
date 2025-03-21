provider "azurerm" {
  features {}
  subscription_id = jsondecode(file("${path.module}/config.json"))["vm_id"]
}

# Référence au groupe de ressources existant
data "azurerm_resource_group" "rg" {
  name = "rg-group-034"
}

# Référence à la VM existante
data "azurerm_virtual_machine" "vm" {
  name                = "vm-kub-001"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Configuration pour le provisionnement via SSH
resource "null_resource" "vm_provisioner" {
  # Déclencher uniquement lors de la première exécution ou lorsque triggered explicitement
  triggers = {
    vm_id = data.azurerm_virtual_machine.vm.id
  }

  # Connexion SSH
  connection {
    type        = "ssh"
    host        = "68.221.141.239"
    user        = "adminuser"
    private_key = file("~/.ssh/id_rsa")
  }

  # Création du fichier
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/apt/keyrings",
      "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor | sudo tee /etc/apt/keyrings/kubernetes-apt-keyring.gpg > /dev/null",
      "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list",
      "sudo apt update",
      "sudo apt install -y -o Dpkg::Options::='--force-overwrite' kubeadm kubelet kubectl",
      "touch nouveau_fichier.txt"
    ]
  }
}