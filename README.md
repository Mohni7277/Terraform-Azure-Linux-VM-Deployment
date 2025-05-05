# Terraform-linux
Terraform Azure VM Deployment
This Terraform configuration deploys a Linux virtual machine (VM) in Microsoft Azure with SSH access and basic configurations.

Features
Creates a complete VM environment including:

Resource group

Virtual network and subnet

Network security group with SSH rule

Public IP address

Network interface

Ubuntu 22.04 LTS VM

SSH key authentication

Optional setup script provisioning

Outputs connection information

Prerequisites
Azure Account: Active Azure subscription

Terraform: v1.0+ installed

Azure CLI: Installed and logged in (az login)

SSH Key Pair: Existing key pair or generate new ones:

bash
ssh-keygen -t rsa -b 4096 -f azurekey
Deployment Steps
Clone the repository:

bash
git clone <repository-url>
cd <repository-directory>
Initialize Terraform:

bash
terraform init
Review execution plan:

bash
terraform plan
Deploy infrastructure:

bash
terraform apply
Connect to VM (after deployment completes):

bash
ssh -i azurekey mohni@<public-ip>
Configuration
Main Variables
location: Azure region (default: "Central India")

vm_size: VM instance size (default: "Standard_B1s")

admin_username: SSH login username (default: "mohni")

ssh_public_key: Path to public key file (default: "azurekey.pub")

Optional Customization
VM Configuration:

Modify vm_size in main.tf for different instance types

Change source_image_reference for different OS images

Network Configuration:

Adjust address_space and address_prefixes in VNet/subnet

Modify NSG rules in azurerm_network_security_group resource

Provisioning:

Edit setup.sh for custom post-deployment configuration

Add additional provisioner blocks as needed

Outputs
After successful deployment, Terraform will display:

vm_private_ip: Private IP address of the VM

vm_public_ip: Public IP address for SSH access

ssh_command: Pre-formatted SSH connection command

Clean Up
To destroy all created resources:

bash
terraform destroy
Troubleshooting
Common Issues
SSH Connection Failed:

Verify the public IP is correct

Check that azurekey private key exists locally

Confirm NSG allows SSH (port 22) from your IP

Public IP Not Showing:

Dynamic IPs may take a few minutes to appear

Run terraform refresh to update state

Provisioning Errors:

Check /var/log/cloud-init-output.log on the VM

Review Azure serial console output

Security Notes
By default, SSH is open to all IP addresses (0.0.0.0/0)

For production environments, restrict source_address_prefix in the NSG rule

Consider using Azure Key Vault for SSH key management
