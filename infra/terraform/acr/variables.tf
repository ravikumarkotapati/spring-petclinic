variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for CI/CD shared services."
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "centralus"
}

variable "name_prefix" {
  type        = string
  description = "Prefix used when acr_name is not supplied."
  default     = "petclinicacr"
}

variable "acr_name" {
  type        = string
  description = "Optional globally unique ACR name. Leave blank to generate one."
  default     = ""

  validation {
    condition     = var.acr_name == "" || can(regex("^[a-zA-Z0-9]{5,50}$", var.acr_name))
    error_message = "ACR name must be blank or 5-50 alphanumeric characters."
  }
}

variable "acr_sku" {
  type        = string
  description = "ACR SKU."
  default     = "Basic"
}

variable "environment" {
  type        = string
  description = "Environment tag."
  default     = "dev"
}

variable "acr_pull_principal_ids" {
  type        = list(string)
  description = "Optional managed identity principal IDs that should receive AcrPull."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Additional tags."
  default     = {}
}
