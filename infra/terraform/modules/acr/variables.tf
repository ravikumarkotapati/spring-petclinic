variable "name" {
  type        = string
  description = "Globally unique Azure Container Registry name."

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.name))
    error_message = "ACR name must be 5-50 alphanumeric characters."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Resource group where the ACR is deployed."
}

variable "location" {
  type        = string
  description = "Azure region for the ACR."
}

variable "sku" {
  type        = string
  description = "ACR SKU."
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "ACR SKU must be Basic, Standard or Premium."
  }
}

variable "acr_pull_principal_ids" {
  type        = list(string)
  description = "Optional managed identity principal IDs that should receive AcrPull."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}
