output client_object_id {
    value = data.azurerm_client_config.current.object_id
}
output client_tenant_id {
    value = data.azurerm_client_config.current.tenant_id
}