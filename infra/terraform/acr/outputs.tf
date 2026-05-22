output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "Resource group name."
}

output "acr_name" {
  value       = module.acr.name
  description = "ACR name."
}

output "acr_login_server" {
  value       = module.acr.login_server
  description = "ACR login server."
}

output "acr_id" {
  value       = module.acr.id
  description = "ACR resource ID."
}
