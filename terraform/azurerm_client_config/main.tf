data azuread_client_config current {}

data azurerm_client_config current {}

data external account_info {
  program                      = [
                                 "az",
                                 "ad",
                                 "signed-in-user",
                                 "show",
                                 "--query",
                                 "{object_id:id}",
                                 "-o",
                                 "json",
                                 ]
}
