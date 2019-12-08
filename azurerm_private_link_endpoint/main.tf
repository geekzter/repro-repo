resource "azurerm_resource_group" "repro" {
  name                         = "${var.prefix}-private-endpoint-issue"
  location                     = var.location
}

resource "azurerm_virtual_network" "network" {
  name                         = "${var.prefix}-vnet"
  address_space                = ["10.0.0.0/16"]
  location                     = azurerm_resource_group.repro.location
  resource_group_name          = azurerm_resource_group.repro.name
}

resource "azurerm_subnet" "subnet" {
  name                         = "${var.prefix}-subnet"
  resource_group_name          = azurerm_resource_group.repro.name
  virtual_network_name         = azurerm_virtual_network.network.name
  address_prefix               = "10.0.1.0/24"
  enforce_private_link_endpoint_network_policies = false
}

resource "random_string" "password" {
  length                       = 12
  upper                        = true
  lower                        = true
  number                       = true
  special                      = true
  override_special             = "." 
}

resource "azurerm_sql_server" "sql_server" {
  name                         = "${var.prefix}sqlserver"
  resource_group_name          = azurerm_resource_group.repro.name
  location                     = azurerm_resource_group.repro.location
  version                      = "12.0"
  administrator_login          = "dbadmin"
  administrator_login_password = random_string.password.result
}

resource "azurerm_private_link_endpoint" "endpoint" {
  name     = "${var.prefix}-endpoint"
  resource_group_name          = azurerm_resource_group.repro.name
  location                     = azurerm_resource_group.repro.location
  subnet_id                    = azurerm_subnet.subnet.id

  private_service_connection {
    is_manual_connection       = false
    name                       = "${var.prefix}-endpoint-connection"
    private_connection_resource_id = azurerm_sql_server.sql_server.id
    # BUG: Error: private_service_connection.0.subresource_names.0 must only contain upper or lowercase letters, numbers, underscores, and periods
    subresource_names          = ["sqlServer"]
  }
}