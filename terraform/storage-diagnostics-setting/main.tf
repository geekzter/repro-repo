locals {
  resource_group_name          = "storage-${lower(random_string.suffix.result)}"
  resource_group_name_short    = substr(lower(replace(local.resource_group_name,"-","")),0,20)

  tags                         = {
    application                = "Storage Diagnostic Setting Issue"
    provisioner                = "Terraform"
  }
}

resource random_string suffix {
  length                       = 4
  upper                        = false
  lower                        = true
  number                       = false
  special                      = false
}

resource azurerm_resource_group rg {
  name                         = local.resource_group_name
  location                     = var.location

  tags                         = local.tags
}

resource azurerm_storage_account diag_storage {
  name                         = "${lower(replace(local.resource_group_name,"-",""))}diag"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  account_kind                 = "StorageV2"
  account_tier                 = "Standard"
  account_replication_type     = "LRS"

  tags                         = local.tags
}

resource azurerm_log_analytics_workspace workspace {
  name                         = "${azurerm_resource_group.rg.name}-loganalytics"
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  sku                          = "Standalone"
  retention_in_days            = 90 

  tags                         = local.tags
}

resource azurerm_storage_account storage {
  name                         = "${local.resource_group_name_short}stor"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  account_kind                 = "StorageV2"
  account_tier                 = "Standard"
  account_replication_type     = "LRS"

  provisioner "local-exec" {
    # Classic methof for storage logging
    command                    = "az storage logging update --account-name ${self.name} --log rwd --retention 90 --services b"
  }

  tags                         = local.tags
}

resource azurerm_monitor_diagnostic_setting storage {
  name                         = "${azurerm_storage_account.storage.name}-logs"
  target_resource_id           = azurerm_storage_account.storage.id
  storage_account_id           = azurerm_storage_account.diag_storage.id
  log_analytics_workspace_id   = azurerm_log_analytics_workspace.workspace.id

  log {
    # Fails, even when having access to private preview of diagnostic log settings
    # https://docs.microsoft.com/en-us/azure/storage/common/monitor-storage?tabs=azure-powershell#configuration
    # https://docs.microsoft.com/en-us/azure/azure-monitor/platform/resource-logs-categories#microsoftstoragestorageaccountsblobservices
    category                   = "StorageWrite"
    enabled                    = true

    retention_policy {
      enabled                  = false
    }
  }
}
