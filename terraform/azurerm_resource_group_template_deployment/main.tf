locals {
  suffix                       = random_string.suffix.result
  tags                         = map(
    "application",               "Dev/Test Lab",
    "environment",               "repro",
    "provisioner",               "terraform",
    "suffix",                    local.suffix,
    "workspace",                 terraform.workspace
  )
}
# Random resource suffix, this will prevent name collisions when creating resources in parallel
resource random_string suffix {
  length                       = 4
  upper                        = false
  lower                        = true
  number                       = false
  special                      = false
}

resource azurerm_resource_group lab_resource_group {
  name                         = "lab-${terraform.workspace}-${local.suffix}"
  location                     = var.location
  tags                         = local.tags
}

resource azurerm_dev_test_lab lab {
  name                         = "${azurerm_resource_group.lab_resource_group.name}-lab"
  location                     = azurerm_resource_group.lab_resource_group.location
  resource_group_name          = azurerm_resource_group.lab_resource_group.name

  tags                         = local.tags
}

resource azurerm_virtual_network custom_network {
  name                         = "${azurerm_resource_group.lab_resource_group.name}-network"
  location                     = azurerm_resource_group.lab_resource_group.location
  resource_group_name          = azurerm_resource_group.lab_resource_group.name
  address_space                = ["10.1.0.0/16"]

  tags                         = local.tags
}

resource azurerm_subnet custom_subnet {
  name                         = "CustomSubnet"
  virtual_network_name         = azurerm_virtual_network.custom_network.name
  resource_group_name          = azurerm_virtual_network.custom_network.resource_group_name
  address_prefixes             = ["10.1.1.0/24"]
}

resource azurerm_resource_group_template_deployment custom_network_association {
  name                         = "${azurerm_resource_group.lab_resource_group.name}-network-association"
  resource_group_name          = azurerm_resource_group.lab_resource_group.name
  deployment_mode              = "Incremental"

  template_content             = file("${path.module}/lab-network-association.json")
  parameters_content           = templatefile("${path.module}/lab-network-association-parameters.json",
    {
      lab_id                   = azurerm_dev_test_lab.lab.id
      virtual_network_id       = azurerm_virtual_network.custom_network.id
      virtual_network_subnet_id= azurerm_subnet.custom_subnet.id
    }
  )

  debug_level                  = "requestContent"
}