terraform {
  required_providers {
    azuread                    = "~> 2.2"
    azurerm                    = "~> 3.0"
  }
  required_version             = "~> 1.0"
}

# Microsoft Azure Resource Manager Provider
provider azurerm {
  features {}
}
