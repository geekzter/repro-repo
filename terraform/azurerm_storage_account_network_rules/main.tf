resource azurerm_resource_group repro {
  name                         = "${var.prefix}-private-endpoint-issue"
  location                     = var.location
}

resource azurerm_storage_account storage {
  name                         = "${var.prefix}storageaccount"
  location                     = azurerm_resource_group.repro.location
  resource_group_name          = azurerm_resource_group.repro.name
  account_tier                 = "Standard"
  account_replication_type     = "LRS"
}

resource azurerm_storage_account_network_rules rules {
  resource_group_name          = azurerm_resource_group.repro.name
  storage_account_name         = azurerm_storage_account.storage.name

  default_action               = "Allow"
  # BUG: Error: "ip_rules.0" is not a valid IPv4 address: "1.0.0.1/30"
  # Documentation states CIDR is supported:
  # https://www.terraform.io/docs/providers/azurerm/r/storage_account_network_rules.html
  ip_rules                     = ["1.0.0.1/30"]
  bypass                       = ["Metrics"]
}
