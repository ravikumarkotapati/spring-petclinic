locals {
  app_config_name = "${var.name_prefix}-${random_string.suffix.result}"

  common_tags = {
    workload    = "spring-petclinic"
    module      = "module-10-app-configuration"
    environment = var.environment
  }
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_app_configuration" "main" {
  name                = local.app_config_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "free"
  local_auth_enabled  = false
  tags                = local.common_tags
}

resource "azurerm_role_assignment" "container_app_reader" {
  scope                = azurerm_app_configuration.main.id
  role_definition_name = "App Configuration Data Reader"
  principal_id         = var.container_app_principal_id
}

resource "azurerm_app_configuration_key" "config_source" {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = "PETCLINIC_CONFIG_SOURCE"
  label                  = var.environment
  value                  = "azure-app-configuration"
  content_type           = "text/plain"
}

resource "azurerm_app_configuration_key" "externalized_config" {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = "PETCLINIC_EXTERNALIZED_CONFIG"
  label                  = var.environment
  value                  = "true"
  content_type           = "text/plain"
}

resource "azurerm_app_configuration_key" "experimental_ui" {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = "PETCLINIC_FEATURE_EXPERIMENTAL_UI"
  label                  = var.environment
  value                  = "false"
  content_type           = "text/plain"
}

resource "azurerm_app_configuration_key" "postgres_url" {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = "POSTGRES_URL"
  label                  = var.environment
  value                  = jsonencode({ uri = "${trimsuffix(var.key_vault_uri, "/")}/secrets/petclinic-postgres-jdbc-url" })
  content_type           = "application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8"
}

resource "azurerm_app_configuration_key" "postgres_user" {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = "POSTGRES_USER"
  label                  = var.environment
  value                  = jsonencode({ uri = "${trimsuffix(var.key_vault_uri, "/")}/secrets/petclinic-postgres-username" })
  content_type           = "application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8"
}

resource "azurerm_app_configuration_key" "postgres_pass" {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = "POSTGRES_PASS"
  label                  = var.environment
  value                  = jsonencode({ uri = "${trimsuffix(var.key_vault_uri, "/")}/secrets/petclinic-postgres-password" })
  content_type           = "application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8"
}
