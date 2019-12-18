<!--- Please keep this note for the community --->

### Community Note

* Please vote on this issue by adding a 👍 [reaction](https://blog.github.com/2016-03-10-add-reactions-to-pull-requests-issues-and-comments/) to the original issue to help the community and maintainers prioritize this request
* Please do not leave "+1" or "me too" comments, they generate extra noise for issue followers and do not help prioritize the request
* If you are interested in working on this issue or have submitted a pull request, please leave a comment

<!--- Thank you for keeping this note for the community --->

### Description

<!--- Please leave a helpful description of the feature request here. --->
Thanks for adding Private Link resources, while it is still in preview!
With both Private Link and Private DNS resources, it should now be possible to provision a Private Endpoint for a PaaS resource e.g. SQL Server, and create the DNS to resolve SQL Server privately. 
However, the bit that is missing to accomplish that is relevant attributes in `azurerm_private_endpoint`, so a DNS record can be created. Currently only `id` is exposed, and I propose to add `private_ip_address`.

### New or Affected Resource(s)

<!--- Please list the new or affected resources and data sources. --->

* azurerm_private_endpoint

### Potential Terraform Configuration

<!--- Information about code formatting: https://help.github.com/articles/basic-writing-and-formatting-syntax/#quoting-code --->
This provisions a SQL Server, VNet, Private Endpoint and DNS:

```hcl
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
  override_special             = "." 
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
  # Proposed Attribute for resource azurerm_private_endpoint: private_ip_address
  records                      = [azurerm_private_endpoint.endpoint.private_ip_address]
}

resource azurerm_private_dns_zone_virtual_network_link link {
  name                         = "${azurerm_virtual_network.network.name}-dns"
  resource_group_name          = azurerm_resource_group.repro.name
  private_dns_zone_name        = azurerm_private_dns_zone.sql_server_db_dns_zone.name
  virtual_network_id           = azurerm_virtual_network.network.id
}
```

### References

<!---
Information about referencing Github Issues: https://help.github.com/articles/basic-writing-and-formatting-syntax/#referencing-issues-and-pull-requests

Are there any other GitHub issues (open or closed) or pull requests that should be linked here? Vendor blog posts or documentation? For example:

* https://azure.microsoft.com/en-us/roadmap/virtual-network-service-endpoint-for-azure-cosmos-db/
--->
