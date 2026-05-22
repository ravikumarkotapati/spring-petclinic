output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "Container Apps resource group."
}

output "container_app_name" {
  value       = azurerm_container_app.petclinic.name
  description = "Container App name."
}

output "container_app_fqdn" {
  value       = azurerm_container_app.petclinic.ingress[0].fqdn
  description = "Public Container App FQDN."
}

output "endpoint_url" {
  value       = "https://${azurerm_container_app.petclinic.ingress[0].fqdn}"
  description = "Public HTTPS endpoint."
}

output "deployed_image" {
  value       = local.app_image
  description = "Container image deployed to Container Apps."
}

output "managed_identity_principal_id" {
  value       = azurerm_user_assigned_identity.container_app.principal_id
  description = "User-assigned managed identity principal ID."
}
