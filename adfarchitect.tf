terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.81.0"
    }
  }
}

#deploying configure tenant
provider "azurerm"{
   features {}
   tenant_id = ""
}

#create resource group
resource "azurerm_resource_group" "rg" {
  name     = "ADF-Architecture"
  location = "West Us"
}

#create azure data factory
resource "azurerm_data_factory" "df" {
  name                = "factorydataline"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

#azure data lake 2
resource "azurerm_data_lake_store" "dlstore" {
  name                = "datalakestg"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "eastus2"
  encryption_state    = "Enabled"
  encryption_type     = "ServiceManaged"
}

#sql Db
resource "azurerm_sql_server" "server101" {
  name                         = "dlqlserver"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = "West US"
  version                      = "12.0"
  administrator_login          = "imaga"
  administrator_login_password = "Password123!"

  tags = {
    environment = "terraform Demo"
  }
}

resource "azurerm_storage_account" "stgacct" {
  name                     = "storageacctname"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_sql_database" "sqldb" {
  name                = "sqldatabase"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "West US"
  server_name         = azurerm_sql_server.server101.name

  extended_auditing_policy {
    storage_endpoint                        = azurerm_storage_account.stgacct.primary_blob_endpoint
    storage_account_access_key              = azurerm_storage_account.stgacct.primary_access_key
    storage_account_access_key_is_secondary = true
    retention_in_days                       = 6
  }

  tags = {
    environment = "terraform Demo"
  }
}
#Data Lake storage
data "azurerm_client_config" "current" {
}

resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "df-to-dl" {
  name                  = "datalakestorageacct"
  resource_group_name   = azurerm_resource_group.rg.name
  data_factory_name     = azurerm_data_factory.df.name
  service_principal_id  = data.azurerm_client_config.current.client_id
  service_principal_key = "exampleKey"
  tenant                = ""
  url                   = "https://datalakestoragegen2"
}

#sql Database
 resource "azurerm_data_factory_linked_service_azure_sql_database" "df-to-sql" {
  name                = "example"
  resource_group_name = azurerm_resource_group.rg.name
  data_factory_name   = azurerm_data_factory.df.name
  connection_string   = "data source=serverhostname;initial catalog=master;user id=testUser;Password=test;integrated security=False;encrypt=True;connection timeout=30"
}
