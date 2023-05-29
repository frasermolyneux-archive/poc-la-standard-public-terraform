data "azurerm_managed_api" "keyvault" {
  for_each = toset(var.locations)

  name     = "keyvault"
  location = azurerm_resource_group.kv[each.value].name
}

resource "azurerm_api_connection" "keyvault" {
  for_each = toset(var.locations)

  name                = "keyvault-connection"
  resource_group_name = azurerm_resource_group.kv[each.value].name
  managed_api_id      = data.azurerm_managed_api.keyvault.id
  display_name        = "Key Vault"

  parameter_values = {
    VaultUri = azurerm_key_vault.kv[each.value].vault_uri
    authProvider = {
      Type = "ManagedServiceIdentity"
    }
  }

  lifecycle {
    # NOTE: since the connectionString is a secure value it's not returned from the API
    ignore_changes = ["parameter_values"]
  }
}
