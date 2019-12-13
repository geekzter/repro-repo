locals {
  resource_group_name          = "pipeline-storage-issue-${lower(random_string.suffix.result)}"
  resource_group_name_short    = substr(lower(replace(local.resource_group_name,"-","")),0,20)

  tags                         = {
    application                = "Pipeline-Storage Issue"
  }
}

data "http" "localpublicip" {
  url                          = "http://ipinfo.io/ip"
}

resource "random_string" "suffix" {
  length                       = 4
  upper                        = false
  lower                        = true
  number                       = false
  special                      = false
}

resource "azurerm_resource_group" "app_rg" {
  name                         = local.resource_group_name
  location                     = var.location

  tags                         = local.tags
}

resource "azurerm_storage_account" "app_storage" {
  name                         = "${local.resource_group_name_short}stor"
  location                     = azurerm_resource_group.app_rg.location
  resource_group_name          = azurerm_resource_group.app_rg.name
  account_kind                 = "StorageV2"
  account_tier                 = "Standard"
  account_replication_type     = "ZRS"
 
  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices","Logging","Metrics","AzureServices"] # Logging, Metrics, AzureServices, or None.
    # Without this hole we can't make (automated) changes. Disable it later in the interactive demo
    ip_rules                   = [chomp(data.http.localpublicip.body)]
  } 

  provisioner "local-exec" {
    command                    = "./enable_storage_logging.ps1 -StorageAccountName ${self.name} -ResourceGroupName ${self.resource_group_name}"
    interpreter                = ["pwsh", "-nop", "-Command"]
  }

  tags                         = local.tags
}

# BUG: 1.0;2019-11-29T15:10:06.7720881Z;GetContainerProperties;IpAuthorizationError;403;6;6;authenticated;XXXXXXX;XXXXXXX;blob;"https://XXXXXXX.blob.core.windows.net:443/data?restype=container";"/";ad97678d-101e-0016-5ec7-a608d2000000;0;10.139.212.72:44506;2018-11-09;481;0;130;246;0;;;;;;"Go/go1.12.6 (amd64-linux) go-autorest/v13.0.2 tombuildsstuff/giovanni/v0.5.0 storage/2018-11-09";;
resource "azurerm_storage_container" "app_storage_container" {
  name                         = "data"
  storage_account_name         = azurerm_storage_account.app_storage.name
  container_access_type        = "private"
}

resource "azurerm_storage_blob" "app_storage_blob_sample" {
  name                         = "sample.txt"
  storage_account_name         = azurerm_storage_account.app_storage.name
  storage_container_name       = azurerm_storage_container.app_storage_container.name

  type                         = "block"
  source                       = "sample.txt"
}