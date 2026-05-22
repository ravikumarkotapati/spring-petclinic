variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for App Configuration."
  default     = "rg-petclinic-config-dev"
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "centralus"
}

variable "name_prefix" {
  type        = string
  description = "Resource name prefix."
  default     = "petclinic-config"
}

variable "environment" {
  type        = string
  description = "Environment tag and App Configuration label."
  default     = "prod"
}

variable "container_app_principal_id" {
  type        = string
  description = "Managed identity principal ID used by the Container App."
}

variable "key_vault_uri" {
  type        = string
  description = "Key Vault URI that contains database secrets."
  default     = "https://petclinicdbqevd19kv.vault.azure.net/"
}
