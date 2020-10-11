# Microsoft Azure Resource Manager Provider
provider "azurerm" {
    version = "= 2.31"
    features {
        virtual_machine {
            # Don't do this in production
            delete_os_disk_on_deletion = true
        }
    }
}

provider "random" {
    version = "~> 2.3.0"
}