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
```
# terraform -v
Terraform v0.12.17
```
```hcl
provider "azurerm" {
    version = "= 1.38" 
}
```
<!--- Please run `terraform -v` to show the Terraform core version and provider version(s). If you are not running the latest version of Terraform or the provider, please upgrade because your issue may have already been fixed. [Terraform documentation on provider versioning](https://www.terraform.io/docs/configuration/providers.html#provider-versions). --->

### Affected Resource(s)

<!--- Please list the affected resources and data sources. --->

* `azurerm_private_link_endpoint`

### Terraform Configuration Files

<!--- Information about code formatting: https://help.github.com/articles/basic-writing-and-formatting-syntax/#quoting-code --->

```hcl
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
```
```hcl
variable "prefix" {
  description = "The Prefix used for all resources in this example"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
}
```


### Debug Output

<!---
Please provide a link to a GitHub Gist containing the complete debug output. Please do NOT paste the debug output in the issue; just paste a link to the Gist.

To obtain the debug output, see the [Terraform documentation on debugging](https://www.terraform.io/docs/internals/debugging.html).
--->

### Panic Output

<!--- If Terraform produced a panic, please provide a link to a GitHub Gist containing the output of the `crash.log`. --->
`Error: private_service_connection.0.subresource_names.0 must only contain upper or lowercase letters, numbers, underscores, and periods`


### Expected Behavior

<!--- What should have happened? --->
Private Endpoint created for given sqlServer sub resource (GroupId)

### Actual Behavior

<!--- What actually happened? --->
`Error: private_service_connection.0.subresource_names.0 must only contain upper or lowercase letters, numbers, underscores, and periods`
### Steps to Reproduce

<!--- Please list the steps required to reproduce the issue. --->

1. `terraform apply`

### Important Factoids

<!--- Are there anything atypical about your accounts that we should know? For example: Running in a Azure China/Germany/Government? --->
It appears the regex in ValidatePrivateLinkSubResourceName is single character only (`^[\w\.]$`)

### References

<!---
Information about referencing Github Issues: https://help.github.com/articles/basic-writing-and-formatting-syntax/#referencing-issues-and-pull-requests

Are there any other GitHub issues (open or closed) or pull requests that should be linked here? Such as vendor documentation?
--->

* #4493 
