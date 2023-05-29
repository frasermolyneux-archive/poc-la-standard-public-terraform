resource "azurerm_resource_group" "kv" {
  for_each = toset(var.locations)

  name     = format("rg-kv-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)
  location = each.value

  tags = var.tags
}

resource "azurerm_key_vault" "kv" {
  for_each = toset(var.locations)

  name                = format("kv%s%s", lower(random_string.location[each.value].result), var.environment)
  location            = azurerm_resource_group.kv[each.value].location
  resource_group_name = azurerm_resource_group.kv[each.value].name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  soft_delete_retention_days = 7

  enable_rbac_authorization = true
  purge_protection_enabled  = true

  sku_name = "standard"

  public_network_access_enabled = true
  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}

resource "azurerm_monitor_diagnostic_setting" "kv" {
  for_each = toset(var.locations)

  name = azurerm_log_analytics_workspace.law.name

  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  target_resource_id = azurerm_key_vault.kv[each.value].id

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }

  enabled_log {
    category = "AuditEvent"

    retention_policy {
      enabled = false
    }
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"

    retention_policy {
      enabled = false
    }
  }
}
