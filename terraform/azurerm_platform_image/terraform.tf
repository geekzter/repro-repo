terraform {
  required_providers {
    azurerm                    = "= 2.92"
  }
  required_version             = "~> 1.0"
}

provider azurerm {
  features {}
}