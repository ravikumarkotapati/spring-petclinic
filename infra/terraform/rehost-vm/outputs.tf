output "resource_group_name" {
  description = "Resource group containing the rehosted VM landing pattern."
  value       = azurerm_resource_group.main.name
}

output "vm_name" {
  description = "Azure VM name."
  value       = azurerm_linux_virtual_machine.app.name
}

output "public_ip_address" {
  description = "Static public IP assigned to the VM."
  value       = azurerm_public_ip.app.ip_address
}

output "app_url" {
  description = "HTTP URL for the NGINX ingress endpoint."
  value       = "http://${azurerm_public_ip.app.fqdn}"
}

output "ssh_command" {
  description = "SSH command for VM troubleshooting."
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.app.fqdn}"
}

output "key_vault_name" {
  description = "Key Vault used for application config and secrets."
  value       = azurerm_key_vault.petclinic.name
}

output "log_analytics_workspace_name" {
  description = "Log Analytics workspace used by Azure Monitor Agent."
  value       = azurerm_log_analytics_workspace.main.name
}

output "recovery_services_vault_name" {
  description = "Recovery Services vault used for VM backup."
  value       = azurerm_recovery_services_vault.main.name
}

output "backup_policy_name" {
  description = "VM backup policy name."
  value       = azurerm_backup_policy_vm.daily.name
}
