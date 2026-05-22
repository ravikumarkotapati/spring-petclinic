output "id" {
  value       = azurerm_container_registry.main.id
  description = "ACR resource ID."
}

output "name" {
  value       = azurerm_container_registry.main.name
  description = "ACR name."
}

output "login_server" {
  value       = azurerm_container_registry.main.login_server
  description = "ACR login server."
}

output "identity_principal_id" {
  value       = azurerm_container_registry.main.identity[0].principal_id
  description = "System-assigned identity principal ID."
}
