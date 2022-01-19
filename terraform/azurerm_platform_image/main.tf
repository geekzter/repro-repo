resource azurerm_resource_group repro {
  name                         = "repro-rg"
  location                     = "westeurope"
}

resource azurerm_virtual_network network {
  name                         = "repro-network"
  location                     = azurerm_resource_group.repro.location
  resource_group_name          = azurerm_resource_group.repro.name
  address_space                = ["192.168.0.0/28"]
}

resource azurerm_subnet subnet {
  name                         = "VMSubnet"
  virtual_network_name         = azurerm_virtual_network.network.name
  resource_group_name          = azurerm_resource_group.repro.name
  address_prefixes             = azurerm_virtual_network.network.address_space
}

resource azurerm_public_ip linux_pip {
  name                         = "linux-pip"
  location                     = azurerm_resource_group.repro.location
  resource_group_name          = azurerm_resource_group.repro.name
  allocation_method            = "Static"
  sku                          = "Standard"
}

resource azurerm_network_interface linux_nic {
  name                         = "linux-nic"
  location                     = azurerm_resource_group.repro.location
  resource_group_name          = azurerm_resource_group.repro.name

  ip_configuration {
    name                     = "ipconfig"
    subnet_id                = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id     = azurerm_public_ip.linux_pip.id
  }  
}

data azurerm_platform_image ubuntu {
  location                     = azurerm_resource_group.repro.location
  publisher                    = "Canonical"
  offer                        = "UbuntuServer"
  sku                          = "18.04-LTS"
}

resource azurerm_linux_virtual_machine ubuntu {
  name                         = "ubuntuvm"
  location                     = azurerm_resource_group.repro.location
  resource_group_name          = azurerm_resource_group.repro.name
  size                         = "Standard_D2s_v3"
  admin_username               = "demouser"
  network_interface_ids        = [azurerm_network_interface.linux_nic.id]

  admin_ssh_key {
    username                   = "demouser"
    public_key                 = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching                    = "ReadWrite"
    storage_account_type       = "Standard_LRS"
  }

  # BUG: Error: No subscription ID found in: "Subscriptions/00000000-0000-0000-0000-000000000000/Providers/Microsoft.Compute/Locations/westeurope/Publishers/Canonical/ArtifactTypes/VMImage/Offers/UbuntuServer/Skus/18.04-LTS/Versions/18.04.202201180"
  # BUG: Error: ID was missing the 'resourceGroups' element
  source_image_id              = data.azurerm_platform_image.ubuntu.id
}