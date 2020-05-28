resource azurerm_resource_group repro {
  name                         = "${var.prefix}-private-endpoint-issue"
  location                     = var.location
}

resource azurerm_virtual_network network {
  name                         = "${var.prefix}-vnet"
  address_space                = ["10.0.0.0/16"]
  location                     = azurerm_resource_group.repro.location
  resource_group_name          = azurerm_resource_group.repro.name
}

resource azurerm_subnet subnet {
  name                         = "${var.prefix}-subnet"
  resource_group_name          = azurerm_resource_group.repro.name
  virtual_network_name         = azurerm_virtual_network.network.name
  address_prefix               = "10.0.1.0/24"
  enforce_private_link_endpoint_network_policies = true
}

resource random_string password {
  length                       = 12
  upper                        = true
  lower                        = true
  number                       = true
  special                      = true
}

resource azurerm_sql_server sql_server {
  name                         = "${var.prefix}sqlserver"
  resource_group_name          = azurerm_resource_group.repro.name
  location                     = azurerm_resource_group.repro.location
  version                      = "12.0"
  administrator_login          = "dbadmin"
  administrator_login_password = random_string.password.result
}

resource azurerm_private_endpoint endpoint {
  name                         = "${var.prefix}-endpoint"
  resource_group_name          = azurerm_resource_group.repro.name
  location                     = azurerm_resource_group.repro.location
  subnet_id                    = azurerm_subnet.subnet.id

  private_service_connection {
    is_manual_connection       = false
    name                       = "${var.prefix}-endpoint-connection"
    private_connection_resource_id = azurerm_sql_server.sql_server.id
    subresource_names          = ["sqlServer"]
  }
}

resource azurerm_private_dns_zone sql_server_db_dns_zone {
  name                         = "privatelink.database.windows.net"
  resource_group_name          = azurerm_resource_group.repro.name
}

resource azurerm_private_dns_a_record sql_server_dns_record {
  name                         = azurerm_sql_server.sql_server.name
  zone_name                    = azurerm_private_dns_zone.sql_server_db_dns_zone.name
  resource_group_name          = azurerm_resource_group.repro.name
  ttl                          = 300
  # Fixed
  records                      = [azurerm_private_endpoint.endpoint.private_service_connection[0].private_ip_address]
}

resource azurerm_private_dns_zone_virtual_network_link link {
  name                         = "${azurerm_virtual_network.network.name}-dns"
  resource_group_name          = azurerm_resource_group.repro.name
  private_dns_zone_name        = azurerm_private_dns_zone.sql_server_db_dns_zone.name
  virtual_network_id           = azurerm_virtual_network.network.id
}