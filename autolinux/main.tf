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

locals {
  ssh_public_key  = fileexists("azurekey.pub") ? file("azurekey.pub") : ""
  ssh_private_key = fileexists("azurekey") ? file("azurekey") : ""
  setup_script    = fileexists("./setup.sh") ? file("./setup.sh") : ""
}

resource "azurerm_resource_group" "vm" {
  name     = "vm-resources"
  location = "Central India"
  tags = {
    Environment = "Development"
    CreatedBy   = "Terraform"
  }
}

resource "azurerm_virtual_network" "vm-net" {
  name                = "vm-net-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name
}

resource "azurerm_subnet" "vm-subnet" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.vm.name
  virtual_network_name = azurerm_virtual_network.vm-net.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "vm-nsg" {
  name                = "vm-nsg"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name

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
}

resource "azurerm_public_ip" "vm-pip" {
  name                = "vm-public-ip"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "vm-nic" {
  name                = "vm-nic"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm-pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.vm-nic.id
  network_security_group_id = azurerm_network_security_group.vm-nsg.id
}

resource "azurerm_linux_virtual_machine" "vm-terraform" {
  name                = "vm-terraform-vm"
  resource_group_name = azurerm_resource_group.vm.name
  location            = azurerm_resource_group.vm.location
  size                = "Standard_B1s"
  admin_username      = "mohni"
  disable_password_authentication = true
  network_interface_ids = [azurerm_network_interface.vm-nic.id]
  
  admin_ssh_key {
    username   = "mohni"
    public_key = local.ssh_public_key
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

  depends_on = [azurerm_public_ip.vm-pip]

  provisioner "file" {
    source      = "./setup.sh"
    destination = "/home/mohni/setup.sh"

    connection {
      type        = "ssh"
      user        = "mohni"
      private_key = local.ssh_private_key
      host        = self.public_ip_address
      timeout     = "10m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/mohni/setup.sh",
      "sudo /bin/bash /home/mohni/setup.sh"
    ]

    connection {
      type        = "ssh"
      user        = "mohni"
      private_key = file("azurekey")
      host        = self.public_ip_address
      timeout     = "30m"  # Increased from 10m to 30m
    }
  }
}

output "vm_private_ip" {
  value = azurerm_network_interface.vm-nic.private_ip_address
}

output "vm_public_ip" {
  value = azurerm_linux_virtual_machine.vm-terraform.public_ip_address
  depends_on = [
    azurerm_linux_virtual_machine.vm-terraform
  ]
}

output "ssh_command" {
  value = "ssh -i azurekey mohni@${azurerm_linux_virtual_machine.your_vm.public_ip_address}"
}
