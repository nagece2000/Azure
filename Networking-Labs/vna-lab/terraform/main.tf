
# VNA-VNET Lab - Terraform Configuration
# Step 1: Resource Group Creation

# Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Variables
variable "resource_group_name" {
    description = "Name of the resource group"
    type = string
    default = "rg-vna-lab"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

# Resource group
resource "azurerm_resource_group" "vna_lab" {
    name = var.resource_group_name
    location = var.location

  tags = {
    Environment = "Lab"
    Purpose     = "VNA-VNET Networking Lab"
    CreatedBy   = "Terraform"
    Project     = "VNA vs VNet Peering Comparison"
  }
}


# ============================================
# VIRTUAL NETWORKS
# ============================================

# Hub Virtual Network (for NVA)
resource "azurerm_virtual_network" "hub_vnet" {
  name                = "hub-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.vna_lab.location
  resource_group_name = azurerm_resource_group.vna_lab.name

    tags = {
    Environment = "Lab"
    Purpose     = "Hub VNet for NVA"
    Role        = "Hub"
  }
}

# Hub Subnet (for NVA VM)
resource "azurerm_subnet" "hub_nva_subnet" {
  name                 = "nva-subnet"
  resource_group_name  = azurerm_resource_group.vna_lab.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Spoke1 Virtual Network
resource "azurerm_virtual_network" "spoke1_vnet" {
  name                = "spoke1-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.vna_lab.location
  resource_group_name = azurerm_resource_group.vna_lab.name

    tags = {
    Environment = "Lab"
    Purpose     = "Spoke1 VNet for test VM"
    Role        = "Spoke"
  }
}

# Spoke1 Subnet
resource "azurerm_subnet" "spoke1_vm_subnet" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.vna_lab.name
  virtual_network_name = azurerm_virtual_network.spoke1_vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

# Spoke2 Virtual Network
resource "azurerm_virtual_network" "spoke2_vnet" {
  name                = "spoke2-vnet"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.vna_lab.location
  resource_group_name = azurerm_resource_group.vna_lab.name

  tags = {
    Environment = "Lab"
    Purpose     = "Spoke2 VNet for test VM"
    Role        = "Spoke"
  }
}

# Spoke2 Subnet
resource "azurerm_subnet" "spoke2_vm_subnet" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.vna_lab.name
  virtual_network_name = azurerm_virtual_network.spoke2_vnet.name
  address_prefixes     = ["10.2.1.0/24"]
}

# =============================
# Virtual Machine
# =============================

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureuser"
}

variable "admin_ssh_key" {
  description = "SSH public key for VM access"
  type        = string
  # You'll need to provide this when running terraform apply
}

variable "vm_size" {
  description = "Size of the VMs"
  type        = string
  default     = "Standard_B1s"
}

variable "my_public_ip" {
  description = "Your public IP address for SSH access (format: x.x.x.x/32)"
  type        = string
  # Get your IP from: https://whatismyipaddress.com or run: curl ifconfig.me
}

# ============================================
# PUBLIC IPs
# ============================================

# Public IP for Spoke1 VM
resource "azurerm_public_ip" "spoke1_vm_pip" {
  name                = "spoke1-vm-pip"
  location            = azurerm_resource_group.vna_lab.location
  resource_group_name = azurerm_resource_group.vna_lab.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = "Lab"
    Purpose     = "Spoke1 VM Public IP"
  }
}

# Public IP for Spoke2 VM
resource "azurerm_public_ip" "spoke2_vm_pip" {
  name                = "spoke2-vm-pip"
  location            = azurerm_resource_group.vna_lab.location
  resource_group_name = azurerm_resource_group.vna_lab.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = "Lab"
    Purpose     = "Spoke2 VM Public IP"
  }
}

# Public IP for NVA VM
resource "azurerm_public_ip" "nva_vm_pip" {
  name                = "nva-vm-pip"
  location            = azurerm_resource_group.vna_lab.location
  resource_group_name = azurerm_resource_group.vna_lab.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = "Lab"
    Purpose     = "NVA VM Public IP"
  }
}

# ============================================
# NETWORK INTERFACES
# ============================================

# NIC for Spoke1 VM
resource "azurerm_network_interface" "spoke1_vm_nic" {
  name                = "spoke1-vm-nic"
  location            = azurerm_resource_group.vna_lab.location
  resource_group_name = azurerm_resource_group.vna_lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke1_vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.spoke1_vm_pip.id
  }

  tags = {
    Environment = "Lab"
    Purpose     = "Spoke1 VM NIC"
  }
}

# NIC for Spoke2 VM
resource "azurerm_network_interface" "spoke2_vm_nic" {
  name                = "spoke2-vm-nic"
  location            = azurerm_resource_group.vna_lab.location
  resource_group_name = azurerm_resource_group.vna_lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke2_vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.spoke2_vm_pip.id
  }

  tags = {
    Environment = "Lab"
    Purpose     = "Spoke2 VM NIC"
  }
}

# NIC for NVA VM (with IP forwarding enabled)
resource "azurerm_network_interface" "nva_vm_nic" {
  name                 = "nva-vm-nic"
  location             = azurerm_resource_group.vna_lab.location
  resource_group_name  = azurerm_resource_group.vna_lab.name
  enable_ip_forwarding = true  # CRITICAL for NVA functionality

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.hub_nva_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.nva_vm_pip.id
  }

  tags = {
    Environment = "Lab"
    Purpose     = "NVA VM NIC"
    Role        = "Network Virtual Appliance"
  }
}

# ============================================
# VIRTUAL MACHINES
# ============================================

# Spoke1 Test VM
resource "azurerm_linux_virtual_machine" "spoke1_vm" {
  name                = "spoke1-vm"
  location            = azurerm_resource_group.vna_lab.location
  resource_group_name = azurerm_resource_group.vna_lab.name
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.spoke1_vm_nic.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    Environment = "Lab"
    Purpose     = "Test VM in Spoke1"
    Role        = "Test-VM"
  }
}

# Spoke2 Test VM
resource "azurerm_linux_virtual_machine" "spoke2_vm" {
  name                = "spoke2-vm"
  location            = azurerm_resource_group.vna_lab.location
  resource_group_name = azurerm_resource_group.vna_lab.name
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.spoke2_vm_nic.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    Environment = "Lab"
    Purpose     = "Test VM in Spoke2"
    Role        = "Test-VM"
  }
}

# NVA VM (Network Virtual Appliance)
resource "azurerm_linux_virtual_machine" "nva_vm" {
  name                = "nva-vm"
  location            = azurerm_resource_group.vna_lab.location
  resource_group_name = azurerm_resource_group.vna_lab.name
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.nva_vm_nic.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    Environment = "Lab"
    Purpose     = "Network Virtual Appliance"
    Role        = "NVA"
  }
}


# ============================================
# NETWORK SECURITY GROUPS
# ============================================

# NSG for Hub Subnet (NVA)
resource "azurerm_network_security_group" "hub_nsg" {
  name                = "hub-nsg"
  location            = azurerm_resource_group.vna_lab.location
  resource_group_name = azurerm_resource_group.vna_lab.name

  # Allow SSH from your IP
  security_rule {
    name                       = "Allow-SSH-From-MyIP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.my_public_ip
    destination_address_prefix = "*"
  }

    # Allow all traffic from Spoke1 VNet (for NVA routing)
  security_rule {
    name                       = "Allow-From-Spoke1"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.1.0.0/16"
    destination_address_prefix = "*"
  }

    # Allow all traffic from Spoke2 VNet (for NVA routing)
  security_rule {
    name                       = "Allow-From-Spoke2"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.2.0.0/16"
    destination_address_prefix = "*"
  }

    tags = {
    Environment = "Lab"
    Purpose     = "Hub NSG for NVA"
  }
}


# NSG for Spoke1 Subnet
resource "azurerm_network_security_group" "spoke1_nsg" {
  name                = "spoke1-nsg"
  location            = azurerm_resource_group.vna_lab.location
  resource_group_name = azurerm_resource_group.vna_lab.name

  # Allow SSH from your IP
  security_rule {
    name                       = "Allow-SSH-From-MyIP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.my_public_ip
    destination_address_prefix = "*"
  }

  # Allow all traffic from Hub VNet (NVA)
  security_rule {
    name                       = "Allow-From-Hub"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # Allow all traffic from Spoke2 VNet (for testing)
  security_rule {
    name                       = "Allow-From-Spoke2"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.2.0.0/16"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = "Lab"
    Purpose     = "Spoke1 NSG"
  }
}

# NSG for Spoke2 Subnet
resource "azurerm_network_security_group" "spoke2_nsg" {
  name                = "spoke2-nsg"
  location            = azurerm_resource_group.vna_lab.location
  resource_group_name = azurerm_resource_group.vna_lab.name

  # Allow SSH from your IP
  security_rule {
    name                       = "Allow-SSH-From-MyIP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.my_public_ip
    destination_address_prefix = "*"
  }

  # Allow all traffic from Hub VNet (NVA)
  security_rule {
    name                       = "Allow-From-Hub"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # Allow all traffic from Spoke1 VNet (for testing)
  security_rule {
    name                       = "Allow-From-Spoke1"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.1.0.0/16"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = "Lab"
    Purpose     = "Spoke2 NSG"
  }
}

# ============================================
# SUBNET-NSG ASSOCIATIONS
# ============================================

# Associate Hub NSG with Hub Subnet
resource "azurerm_subnet_network_security_group_association" "hub_nsg_assoc" {
  subnet_id                 = azurerm_subnet.hub_nva_subnet.id
  network_security_group_id = azurerm_network_security_group.hub_nsg.id
}

# Associate Spoke1 NSG with Spoke1 Subnet
resource "azurerm_subnet_network_security_group_association" "spoke1_nsg_assoc" {
  subnet_id                 = azurerm_subnet.spoke1_vm_subnet.id
  network_security_group_id = azurerm_network_security_group.spoke1_nsg.id
}

# Associate Spoke2 NSG with Spoke2 Subnet
resource "azurerm_subnet_network_security_group_association" "spoke2_nsg_assoc" {
  subnet_id                 = azurerm_subnet.spoke2_vm_subnet.id
  network_security_group_id = azurerm_network_security_group.spoke2_nsg.id
}

# ============================================
# OUTPUTS
# ============================================

output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.vna_lab.name
}

output "resource_group_id" {
  description = "ID of the created resource group"
  value       = azurerm_resource_group.vna_lab.id
}

output "location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.vna_lab.location
}

output "hub_vnet_id" {
  description = "ID of Hub VNet"
  value       = azurerm_virtual_network.hub_vnet.id
}

output "spoke1_vnet_id" {
  description = "ID of Spoke1 VNet"
  value       = azurerm_virtual_network.spoke1_vnet.id
}

output "spoke2_vnet_id" {
  description = "ID of Spoke2 VNet"
  value       = azurerm_virtual_network.spoke2_vnet.id
}

output "spoke1_vm_private_ip" {
  description = "Private IP of Spoke1 VM"
  value       = azurerm_network_interface.spoke1_vm_nic.private_ip_address
}

output "spoke2_vm_private_ip" {
  description = "Private IP of Spoke2 VM"
  value       = azurerm_network_interface.spoke2_vm_nic.private_ip_address
}

output "nva_vm_private_ip" {
  description = "Private IP of NVA VM"
  value       = azurerm_network_interface.nva_vm_nic.private_ip_address
}

output "spoke1_vm_public_ip" {
  description = "Public IP of Spoke1 VM (for SSH)"
  value       = azurerm_public_ip.spoke1_vm_pip.ip_address
}

output "spoke2_vm_public_ip" {
  description = "Public IP of Spoke2 VM (for SSH)"
  value       = azurerm_public_ip.spoke2_vm_pip.ip_address
}

output "nva_vm_public_ip" {
  description = "Public IP of NVA VM (for SSH)"
  value       = azurerm_public_ip.nva_vm_pip.ip_address
}

output "hub_nsg_id" {
  description = "ID of Hub NSG"
  value       = azurerm_network_security_group.hub_nsg.id
}

output "spoke1_nsg_id" {
  description = "ID of Spoke1 NSG"
  value       = azurerm_network_security_group.spoke1_nsg.id
}

output "spoke2_nsg_id" {
  description = "ID of Spoke2 NSG"
  value       = azurerm_network_security_group.spoke2_nsg.id
}

output "hub_nsg_name" {
  description = "Name of Hub NSG"
  value       = azurerm_network_security_group.hub_nsg.name
}

output "spoke1_nsg_name" {
  description = "Name of Spoke1 NSG"
  value       = azurerm_network_security_group.spoke1_nsg.name
}

output "spoke2_nsg_name" {
  description = "Name of Spoke2 NSG"
  value       = azurerm_network_security_group.spoke2_nsg.name
}
