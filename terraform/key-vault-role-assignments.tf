resource "azurerm_role_assignment" "logic" {
  for_each = toset(var.locations)

  scope                = azurerm_key_vault.kv[each.value].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_logic_app_standard.logic[each.value].identity.0.principal_id
}
