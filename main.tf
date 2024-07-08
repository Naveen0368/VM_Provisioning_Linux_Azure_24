provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vm_name" {
  type = string
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type = string
}

variable "vm_size" {
  type = string
  default = "Standard_DS1_v2"
}

variable "vnet_address_space" {
  type = string
  default = "10.0.0.0/16"
}

variable "subnet_address_prefixes" {
  type = string
  default = "10.0.2.0/24"
}

variable "storage_account_type" {
  type = string
  default = "Standard_LRS"
}

variable "os_disk_caching" {
  type = string
  default = "ReadWrite"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.vm_name}-nw"
  address_space       = [var.vnet_address_space]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_prefixes]
}

resource "azurerm_public_ip" "ip" {
  name                = "${var.vm_name}-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nwint" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ip.id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                            = var.vm_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.nwint.id,
  ]

  os_disk {
    caching              = var.os_disk_caching
    storage_account_type = var.storage_account_type
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

data "azurerm_public_ip" "dip" {
  name                = azurerm_public_ip.ip.name
  resource_group_name = var.resource_group_name
}

# Define outputs
output "vm_name" {
  value = azurerm_linux_virtual_machine.vm.name
}

output "private_ip_address" {
  value = azurerm_network_interface.nwint.private_ip_address
}

output "public_ip_address" {
  value = data.azurerm_public_ip.dip.ip_address
}
