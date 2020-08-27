<!---
Please note the following potential times when an issue might be in Terraform core:

* [Configuration Language](https://www.terraform.io/docs/configuration/index.html) or resource ordering issues
* [State](https://www.terraform.io/docs/state/index.html) and [State Backend](https://www.terraform.io/docs/backends/index.html) issues
* [Provisioner](https://www.terraform.io/docs/provisioners/index.html) issues
* [Registry](https://registry.terraform.io/) issues
* Spans resources across multiple providers

If you are running into one of these scenarios, we recommend opening an issue in the [Terraform core repository](https://github.com/hashicorp/terraform/) instead.
--->

<!--- Please keep this note for the community --->

### Community Note

* Please vote on this issue by adding a 👍 [reaction](https://blog.github.com/2016-03-10-add-reactions-to-pull-requests-issues-and-comments/) to the original issue to help the community and maintainers prioritize this request
* Please do not leave "+1" or "me too" comments, they generate extra noise for issue followers and do not help prioritize the request
* If you are interested in working on this issue or have submitted a pull request, please leave a comment

<!--- Thank you for keeping this note for the community --->

### Description
Diagnostic settings can't be added for categories that are used for Azure Storage (currently in preview).

### Terraform (and AzureRM Provider) Version

<!--- Please run `terraform -v` to show the Terraform core version and provider version(s). If you are not running the latest version of Terraform or the provider, please upgrade because your issue may have already been fixed. [Terraform documentation on provider versioning](https://www.terraform.io/docs/configuration/providers.html#provider-versions). --->
Terraform v0.12.29
+ provider.azurerm v2.25.0
+ provider.random v2.3.0

### Affected Resource(s)

<!--- Please list the affected resources and data sources. --->

* `azurerm_monitor_diagnostic_setting`

### Terraform Configuration Files

<!--- Information about code formatting: https://help.github.com/articles/basic-writing-and-formatting-syntax/#quoting-code --->

```hcl
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
```

### Debug Output

<!---
Please provide a link to a GitHub Gist containing the complete debug output. Please do NOT paste the debug output in the issue; just paste a link to the Gist.

To obtain the debug output, see the [Terraform documentation on debugging](https://www.terraform.io/docs/internals/debugging.html).
--->

### Panic Output

<!--- If Terraform produced a panic, please provide a link to a GitHub Gist containing the output of the `crash.log`. --->

### Expected Behavior

<!--- What should have happened? --->
Diagnostic setting created, as it is when configured in the Azure Portal

### Actual Behavior

<!--- What actually happened? --->
Error: Error creating Monitor Diagnostics Setting "storageodgxstor-logs" for Resource "/subscriptions/84c1a2c7-585a-4753-ad28-97f69618cf12/resourceGroups/storage-odgx/providers/Microsoft.Storage/storageAccounts/storageodgxstor": insights.DiagnosticSettingsClient#CreateOrUpdate: Failure responding to request: StatusCode=400 -- Original Error: autorest/azure: Service returned an error. Status=400 Code="BadRequest" Message="Category 'StorageWrite' is not supported."
### Steps to Reproduce

<!--- Please list the steps required to reproduce the issue. --->

1. `terraform init`
1. `terraform apply`

### Important Factoids

<!--- Are there anything atypical about your accounts that we should know? For example: Running in a Azure China/Germany/Government? --->
Azure Storage diagnostic settings are in private preview

### References
Description of Storage Account diagnostic setting categories (StorageRead, StorageWrite, StorageDelete):    
https://docs.microsoft.com/en-us/azure/storage/common/monitor-storage?tabs=azure-powershell#configuration
https://docs.microsoft.com/en-us/azure/azure-monitor/platform/resource-logs-categories#microsoftstoragestorageaccountsblobservices
<!---
Information about referencing Github Issues: https://help.github.com/articles/basic-writing-and-formatting-syntax/#referencing-issues-and-pull-requests

Are there any other GitHub issues (open or closed) or pull requests that should be linked here? Such as vendor documentation?
--->

<!---
* #0000
--->