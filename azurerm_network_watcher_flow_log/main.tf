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