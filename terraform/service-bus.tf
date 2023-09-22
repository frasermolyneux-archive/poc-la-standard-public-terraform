resource "azurerm_resource_group" "sb" {
  for_each = toset(var.locations)

  name     = format("rg-sb-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)
  location = each.value

  tags = var.tags
}

resource "azurerm_servicebus_namespace" "sb" {
  for_each = toset(var.locations)

  name = format("sb-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)

  resource_group_name = azurerm_resource_group.sb[each.value].name
  location            = azurerm_resource_group.sb[each.value].location
  tags                = var.tags

  sku      = "Premium"
  capacity = 1

  public_network_access_enabled = true
  minimum_tls_version           = "1.2"
}
