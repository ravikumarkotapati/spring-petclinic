output "app_configuration_name" {
  description = "Azure App Configuration store name."
  value       = azurerm_app_configuration.main.name
}

output "app_configuration_endpoint" {
  description = "Azure App Configuration data-plane endpoint."
  value       = azurerm_app_configuration.main.endpoint
}

output "resource_group_name" {
  description = "Resource group containing the App Configuration store."
  value       = azurerm_resource_group.main.name
}
