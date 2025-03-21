
# Configuration du provider et du bloc terraform
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Récupérer les données des VMs existantes
data "azurerm_virtual_machine" "vm1" {
  name                = "vm-kub-001"
  resource_group_name = "RG-GROUP-034"
}

data "azurerm_virtual_machine" "vm2" {
  name                = "vm-kub-002"
  resource_group_name = "RG-GROUP-034"
}


# Créer un réseau virtuel
resource "azurerm_virtual_network" "vnet" {
  name                = "kubernetes-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "Spain Central" # Adaptez selon votre région
  resource_group_name = "RG-GROUP-034"
}

# Créer un sous-réseau
resource "azurerm_subnet" "subnet" {
  name                 = "kubernetes-subnet"
  resource_group_name  = "RG-GROUP-034"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Créer des IPs publiques pour les VMs
resource "azurerm_public_ip" "pip1" {
  name                = "vm1-public-ip"
  location            = "Spain Central" # Adaptez selon votre région
  resource_group_name = "RG-GROUP-034"
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

resource "azurerm_public_ip" "pip2" {
  name                = "vm2-public-ip"
  location            = "Spain Central" # Adaptez selon votre région
  resource_group_name = "RG-GROUP-034"
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

# Créer des interfaces réseau pour les VMs avec IPs publiques
resource "azurerm_network_interface" "nic1" {
  name                = "vm1-nic"
  location            = "Spain Central" # Adaptez selon votre région
  resource_group_name = "RG-GROUP-034"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip1.id
  }
}

resource "azurerm_network_interface" "nic2" {
  name                = "vm2-nic"
  location            = "Spain Central" # Adaptez selon votre région
  resource_group_name = "RG-GROUP-034"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip2.id
  }
}

# Créer un groupe de sécurité réseau pour permettre les connexions SSH
resource "azurerm_network_security_group" "nsg" {
  name                = "kubernetes-nsg"
  location            = "Spain Central" # Adaptez selon votre région
  resource_group_name = "RG-GROUP-034"

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
    name                       = "Kubernetes"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["6443", "2379-2380", "10250-10252"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associer le NSG aux interfaces réseau
resource "azurerm_network_interface_security_group_association" "nsg_nic1" {
  network_interface_id      = azurerm_network_interface.nic1.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface_security_group_association" "nsg_nic2" {
  network_interface_id      = azurerm_network_interface.nic2.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Associer les interfaces réseau aux VMs existantes
resource "azurerm_virtual_machine_network_interface_association" "vm1_nic_assoc" {
  network_interface_id    = azurerm_network_interface.nic1.id
  virtual_machine_id      = data.azurerm_virtual_machine.vm1.id
}

resource "azurerm_virtual_machine_network_interface_association" "vm2_nic_assoc" {
  network_interface_id    = azurerm_network_interface.nic2.id
  virtual_machine_id      = data.azurerm_virtual_machine.vm2.id
}

# Outputs pour récupérer les IPs publiques après déploiement
output "vm1_public_ip" {
  value = azurerm_public_ip.pip1.ip_address
}

output "vm2_public_ip" {
  value = azurerm_public_ip.pip2.ip_address
}