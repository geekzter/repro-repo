output aad_client_object_id {
    value = data.azuread_client_config.current.object_id
}
output client_object_id {
    value = data.azurerm_client_config.current.object_id
}
output client_tenant_id {
    value = data.azurerm_client_config.current.tenant_id
}

output user_object_id {
    value = data.external.account_info.result.object_id
}