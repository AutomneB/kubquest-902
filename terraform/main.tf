# Configuration du provider et du bloc terraform
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    ansible = {
      version = "~> 1.3.0"
      source  = "ansible/ansible"
    }

  }
  cloud {

    organization = "CLOUD902"

    workspaces {
      name = "AzureVm"
    }
  }
}


provider "azurerm" {
  features {}
}



# Création du resource group
resource "azurerm_resource_group" "rg" {
  name     = "RG-GROUP-034"
  location = "Spain Central"
}

# Variables pour la configuration du cluster
locals {
  vm_sizes = {
    master = "Standard_D2s_v3" # Taille augmentée pour le master
    worker = "Standard_D1_v2" # Taille augmentée pour le worker
  }
  vm_config = {
    master = {
      name = "vm-kub-master"
      size = local.vm_sizes.master
    }
    workers = [
    { name = "vm-kub-worker1", size = local.vm_sizes.worker },
    { name = "vm-kub-worker2", size = local.vm_sizes.worker } 
   ]
  }
}

# Créer un réseau virtuel
resource "azurerm_virtual_network" "vnet" {
  name                = "kubernetes-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Créer un sous-réseau
resource "azurerm_subnet" "subnet" {
  name                 = "kubernetes-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Créer un groupe de sécurité réseau pour le cluster Kubernetes
resource "azurerm_network_security_group" "nsg" {
  name                = "kubernetes-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Règle pour permettre la communication Kubernetes
  security_rule {
    name                       = "Kubernetes-API"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Kubernetes-etcd"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2379-2380"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Kubernetes-kubelet"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10250"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Kubernetes-scheduler"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10251"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Kubernetes-controller"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10252"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Kubernetes-NodePort"
    priority                   = 1007
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30000-32767"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ------- Master Node Resources -------

# IP publique pour le master
resource "azurerm_public_ip" "master_pip" {
  name                = "master-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

# Interface réseau pour le master
resource "azurerm_network_interface" "master_nic" {
  name                = "master-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.master_pip.id
  }
}

# Association NSG au NIC du master
resource "azurerm_network_interface_security_group_association" "master_nsg_nic" {
  network_interface_id      = azurerm_network_interface.master_nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# VM Master
resource "azurerm_linux_virtual_machine" "master" {
  name                = local.vm_config.master.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = local.vm_config.master.size
  admin_username      = var.instance_username
  network_interface_ids = [
    azurerm_network_interface.master_nic.id,
  ]

  admin_ssh_key {
    username   = var.instance_username
    public_key = local_file.ssh_public_key.content
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    echo "Configuration du nœud master Kubernetes" > /tmp/k8s_setup.log
    # Scripts d'initialisation pour le master peuvent être ajoutés ici
  EOF
  )
}

# ------- Worker Node Resources -------

# IP publique pour le worker
resource "azurerm_public_ip" "worker_pip" {
  count               = length(local.vm_config.workers)
  name                = "worker${count.index + 1}-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

# Interface réseau pour le worker
resource "azurerm_network_interface" "worker_nic" {
  count               = length(local.vm_config.workers)
  name                = "worker${count.index + 1}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.worker_pip[count.index].id
  }
}

# Association NSG au NIC du worker
resource "azurerm_network_interface_security_group_association" "worker_nsg_nic" {
  count                     = length(local.vm_config.workers)
  network_interface_id      = azurerm_network_interface.worker_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# VM Worker
resource "azurerm_linux_virtual_machine" "worker" {
  count               = length(local.vm_config.workers)
  name                = local.vm_config.workers[count.index].name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = local.vm_config.workers[count.index].size
  admin_username      = var.instance_username
  network_interface_ids = [
    azurerm_network_interface.worker_nic[count.index].id,
  ]

  admin_ssh_key {
    username   = var.instance_username
    public_key = local_file.ssh_public_key.content
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    echo "Configuration du nœud worker Kubernetes" > /tmp/k8s_setup.log
    # Scripts d'initialisation pour les workers peuvent être ajoutés ici
  EOF
  )
}

# ------- Outputs -------

output "master_public_ip" {
  value       = azurerm_public_ip.master_pip.ip_address
  description = "L'adresse IP publique du nœud master Kubernetes"
}

output "worker_public_ips" {
  value       = join(", ", azurerm_public_ip.worker_pip[*].ip_address)
  description = "Liste des adresses IP publiques des nœuds worker Kubernetes"
}

output "master_private_ip" {
  value       = azurerm_network_interface.master_nic.private_ip_address
  description = "L'adresse IP privée du nœud master Kubernetes"
}

output "worker_private_ip" {
  value       = length(azurerm_network_interface.worker_nic) > 0 ? azurerm_network_interface.worker_nic[0].private_ip_address : ""
  description = "L'adresse IP privée du nœud worker Kubernetes"
}