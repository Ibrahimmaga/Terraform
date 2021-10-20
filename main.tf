terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.80.0"
    }
  }
}
#deploying ressource group
provider "azurerm"{
   features {}
   tenant_id = "12e2dd65-5024-44c2-83b5-3ca21c04ef0e"
}
resource "azurerm_resource_group" "rg"{
   name = "Terraform-resource"
   location = "West Us"
   tags = {
       environment= "terraform"
       deployedby= "Ibrahim Maga"
   }
}

# deploying Azure Storage
resource "azurerm_storage_account" "sa" {
   name = "mystoragename"
   resource_group_name = "Terraform-resource"
   location = "West Us"
   account_tier = "Standard"
   account_replication_type = "GRS"
   tags = {
      environment = "terraform"
   }
}

# recovery service vault

resource "azurerm_recovery_services_vault" "vault" {
    name = "Terraform-recovery-vault"
    location = "West Us"
    resource_group_name = "Terraform-resource"
    sku = "Standard"
}

# Create VNET
resource "azurerm_virtual_network" "tfVNET" {
    name = "myVnet"
    address_space = ["10.0.0.0/16"]
    location = "West Us"
    resource_group_name = "Terraform-resource"
    tags = {
        environment = "terraform"
    }
}

# Create subnets
resource "azurerm_subnet" "tfsubnet1" {
    name = "mySubnet1"
    resource_group_name = "Terraform-resource"
    virtual_network_name = azurerm_virtual_network.tfVNET.name
    address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "tfsubnet2" {
    name = "mySubnet2"
    resource_group_name = "Terraform-resource"
    virtual_network_name = azurerm_virtual_network.tfVNET.name
    address_prefixes = ["10.0.2.0/24"]
}

# create NSG
resource "azurerm_network_security_group" "nsg"{
    name                = "TestNSG"
    location            = "West Us"
    resource_group_name = "Terraform-resource"
}

resource "azurerm_network_security_rule" "rule1" {
    name = "webport80"
    priority = 1001
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "80"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    resource_group_name = "Terraform-resource"
    network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "rule2" {
    name = "webport8080"
    priority = 1000
    direction = "Inbound"
    access = "Deny"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "8080"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    resource_group_name = "Terraform-resource"
    network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "rule3" {
    name = "webout80"
    priority = 1000
    direction = "Outbound"
    access = "Deny"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "80"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    resource_group_name = "Terraform-resource"
    network_security_group_name = azurerm_network_security_group.nsg.name
}

#Deploying Virtual Machine
data "azurerm_subnet" "tfsubnet1"{
    name = "mySubnet1"
    virtual_network_name = azurerm_virtual_network.tfVNET.name
    resource_group_name = "Terraform-resource"
}

resource "azurerm_public_ip" "pubip" {
    name = "pubip1"
    location = "West Us"
    resource_group_name = "Terraform-resource"
    allocation_method = "Dynamic"
    sku = "Basic"
}

resource "azurerm_network_interface" "NIC" {
    name = "myNIC"
    location = "West US"
    resource_group_name = "Terraform-resource"
    ip_configuration {
        name = "ipconfig"
        subnet_id = azurerm_subnet.tfsubnet1.id
        private_ip_address_allocation = "Dynamic"
    }
}

resource "azurerm_virtual_machine" "main" {
    name = "vm1"
    location = "West Us"
    resource_group_name = "Terraform-resource"
    network_interface_ids = [azurerm_network_interface.NIC.id]
    vm_size = "Standard_DS1_v2"

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04-LTS"
        version   = "latest"
    }

    storage_os_disk {
        name              = "myosdisk1"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    os_profile {
        computer_name  = "hostname"
        admin_username = "imaga"
        admin_password = "Password123!"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

    tags = {
        environment = "Prod"
    }
}

#Deploying WebApp
resource "azurerm_app_service_plan" "svcplan" {
    name = "appServiceplan"
    location = "West Us"
    resource_group_name = "Terraform-resource"
    sku {
        tier = "Standard"
        size = "S1"
    }
}

resource "azurerm_app_service" "webapp" {
    name = "myimagawebapp"
    location = "West Us"
    resource_group_name = "Terraform-resource"
    app_service_plan_id = azurerm_app_service_plan.svcplan.id
    site_config {
        dotnet_framework_version = "v5.0"
        scm_type = "LocalGit"
    }
}

#Deploying Sql server
resource "azurerm_sql_server" "mymssql" {
    name = "mssqlserver101"
    resource_group_name = azurerm_resource_group.rg.name
    location = "West Us"
    version = "12.0"
    administrator_login = "imaga2398"
    administrator_login_password = "pPassword123!"

    extended_auditing_policy {
        storage_endpoint = azurerm_storage_account.sa.primary_blob_endpoint
        storage_account_access_key = azurerm_storage_account.sa.primary_access_key
        storage_account_access_key_is_secondary = true
    }

    tags = {
        environment = "production"
    }
}