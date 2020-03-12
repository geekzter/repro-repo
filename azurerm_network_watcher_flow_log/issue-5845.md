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

### Terraform (and AzureRM Provider) Version

<!--- Please run `terraform -v` to show the Terraform core version and provider version(s). If you are not running the latest version of Terraform or the provider, please upgrade because your issue may have already been fixed. [Terraform documentation on provider versioning](https://www.terraform.io/docs/configuration/providers.html#provider-versions). --->
```
# terraform -v
Terraform v0.12.21
+ provider.azurerm v1.44.0
```

### Affected Resource(s)

<!--- Please list the affected resources and data sources. --->

* `azurerm_network_watcher_flow_log`

### Terraform Configuration Files

<!--- Information about code formatting: https://help.github.com/articles/basic-writing-and-formatting-syntax/#quoting-code --->

```hcl
resource azurerm_resource_group repro {
  name                         = "${var.prefix}-flowlog-issue"
  location                     = var.location
}

# Singleton resource, so assume it exists and reference it
data azurerm_network_watcher watcher {
  name                         = "NetworkWatcher_${var.location}"
  resource_group_name          = "NetworkWatcherRG"
}

resource azurerm_network_security_group nsg {
  name                         = "${azurerm_resource_group.repro.name}-nsg"
  location                     = azurerm_resource_group.repro.location
  resource_group_name          = azurerm_resource_group.repro.name

  security_rule {
    name                       = "AllowRDPOutbound"
    priority                   = 105
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Internet"
  }

  security_rule {
    name                       = "AllowSSHOutbound"
    priority                   = 106
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Internet"
  }
}

resource azurerm_storage_account diag_storage {
  name                         = "${lower(replace(azurerm_resource_group.repro.name,"-",""))}diag"
  resource_group_name          = azurerm_resource_group.repro.name
  location                     = azurerm_resource_group.repro.location
  account_kind                 = "StorageV2"
  account_tier                 = "Standard"
  account_replication_type     = "LRS"
  enable_blob_encryption       = true
  enable_https_traffic_only    = true
}

resource azurerm_log_analytics_workspace workspace {
  name                         = "${azurerm_resource_group.repro.name}-loganalytics"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.repro.name
  sku                          = "Standalone"
  retention_in_days            = 90 
}

# BUG: Resource is not destroyed
resource azurerm_network_watcher_flow_log nsg_logs {
  network_watcher_name         = data.azurerm_network_watcher.watcher.name
  resource_group_name          = data.azurerm_network_watcher.watcher.resource_group_name

  network_security_group_id    = azurerm_network_security_group.nsg.id
  storage_account_id           = azurerm_storage_account.diag_storage.id
  enabled                      = true

  retention_policy {
    enabled                    = true
    days                       = 7
  }

  traffic_analytics {
    enabled                    = true
    workspace_id               = azurerm_log_analytics_workspace.workspace.workspace_id
    workspace_region           = azurerm_log_analytics_workspace.workspace.location
    workspace_resource_id      = azurerm_log_analytics_workspace.workspace.id
  }

  # BUG: self.id references invalid resource id
  #      /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/NetworkWatcherRG/providers/Microsoft.Network/networkWatchers/NetworkWatcher_eastus/networkSecurityGroupId/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/prefix/providers/Microsoft.Network/networkSecurityGroups/prefix-iaas-spoke-network-nsg
  #      instead of:
  #      /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/NetworkWatcherRG/providers/Microsoft.Network/networkWatchers/NetworkWatcher_eastus/flowLogs/Microsoft.Networkprefixprefix-iaas-spoke-network-nsg
  # provisioner local-exec {
  #   when                       = destroy
  #   command                    = "az resource delete --ids ${self.id}"
  # }
}
```
```hcl
variable prefix {
  description = "The Prefix used for all resources in this example"
}

variable location {
  description = "The Azure Region in which all resources in this example should be created."
  default     = "westeurope"
}
```
```hcl
output flow_logs_id {
  value = azurerm_network_watcher_flow_log.nsg_logs.id
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
All resources destroyed

### Actual Behavior

<!--- What actually happened? --->
The `azurerm_network_watcher_flow_log` resource is not destroyed:
`
Error: Error deleting Network Security Group "repro-flowlog-issue-nsg" (Resource Group "repro-flowlog-issue"): network.SecurityGroupsClient#Delete: Failure sending request: StatusCode=400 -- Original Error: Code="InvalidResourceReference" Message="Resource /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/NetworkWatcherRG/providers/Microsoft.Network/networkWatchers/NetworkWatcher_westeurope/FlowLogs/Microsoft.Networkrepro-flowlog-issuerepro-flowlog-issue-nsg referenced by resource /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/repro-flowlog-issue/providers/Microsoft.Network/networkSecurityGroups/repro-flowlog-issue-nsg was not found. Please make sure that the referenced resource exists, and that both resources are in the same region." Details=[]
`

### Steps to Reproduce

<!--- Please list the steps required to reproduce the issue. --->

1. `terraform init`
2. `terraform destroy`
3. `terraform destroy`

### Important Factoids

<!--- Are there anything atypical about your accounts that we should know? For example: Running in a Azure China/Germany/Government? --->
Manually removing the resource with `az resource delete --ids` yields a similar message that the resource can't be found. The resource id exported by `azurerm_network_watcher_flow_log` is `/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/NetworkWatcherRG/providers/Microsoft.Network/networkWatchers/NetworkWatcher_westeurope/networkSecurityGroupId/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/repro-flowlog-issue/providers/Microsoft.Network/networkSecurityGroups/repro-flowlog-issue-nsg`

while this is the id of the resource created: `/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/NetworkWatcherRG/providers/Microsoft.Network/networkWatchers/NetworkWatcher_westeurope/flowLogs/Microsoft.Networkrepro-flowlog-issuerepro-flowlog-issue-nsg`

### References

<!---
Information about referencing Github Issues: https://help.github.com/articles/basic-writing-and-formatting-syntax/#referencing-issues-and-pull-requests

Are there any other GitHub issues (open or closed) or pull requests that should be linked here? Such as vendor documentation?

