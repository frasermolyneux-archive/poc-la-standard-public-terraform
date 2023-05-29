resource "azurerm_resource_group" "logic" {
  for_each = toset(var.locations)

  name     = format("rg-logic-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)
  location = each.value

  tags = var.tags
}

resource "azurerm_service_plan" "logic" {
  for_each = toset(var.locations)

  name = format("sp-logic-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)

  resource_group_name = azurerm_resource_group.logic[each.value].name
  location            = azurerm_resource_group.logic[each.value].location

  os_type  = "Windows"
  sku_name = "WS1"
}

resource "azurerm_monitor_diagnostic_setting" "logic_svcplan" {
  for_each = toset(var.locations)

  name = azurerm_log_analytics_workspace.law.name

  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  target_resource_id = azurerm_service_plan.logic[each.value].id

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_storage_account" "logic" {
  for_each = toset(var.locations)

  name = format("sala%s", lower(random_string.location[each.value].result))

  resource_group_name = azurerm_resource_group.logic[each.value].name
  location            = azurerm_resource_group.logic[each.value].location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version = "TLS1_2"

  public_network_access_enabled = true

  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }
}

resource "azurerm_logic_app_standard" "logic" {
  for_each = toset(var.locations)

  name = format("logic-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)

  version = "~4"

  resource_group_name = azurerm_resource_group.logic[each.value].name
  location            = azurerm_resource_group.logic[each.value].location

  storage_account_name       = azurerm_storage_account.logic[each.value].name
  storage_account_access_key = azurerm_storage_account.logic[each.value].primary_access_key
  app_service_plan_id        = azurerm_service_plan.logic[each.value].id

  https_only = true

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.ai[each.value].instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.ai[each.value].connection_string
    "FUNCTIONS_WORKER_RUNTIME"              = "node"
    "WEBSITE_NODE_DEFAULT_VERSION"          = "~16"
    "keyvault_uri"                          = azurerm_key_vault.kv[each.value].vault_uri
  }

  site_config {
    use_32_bit_worker_process = false

    ftps_state = "Disabled"
  }

  identity {
    type = "SystemAssigned"
  }
}
