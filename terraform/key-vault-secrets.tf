resource "azurerm_key_vault_secret" "kv_example" {
  for_each = toset(var.locations)

  name         = "my-super-secret"
  value        = random_string.location[each.value].result
  key_vault_id = azurerm_key_vault.kv[each.value].id
}

resource "azurerm_key_vault_secret" "kv_example_2" {
  for_each = toset(var.locations)

  name         = "another-super-secret"
  value        = random_string.location[each.value].result
  key_vault_id = azurerm_key_vault.kv[each.value].id
}
