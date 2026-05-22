variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for the managed container replatform target."
  default     = "rg-petclinic-containerapps-dev"
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "centralus"
}

variable "environment" {
  type        = string
  description = "Environment tag."
  default     = "dev"
}

variable "name_prefix" {
  type        = string
  description = "Prefix for Container Apps environment, identity and logging resources."
  default     = "petclinic-ca"
}

variable "container_app_name" {
  type        = string
  description = "Container App name."
  default     = "petclinic-container-app"
}

variable "acr_id" {
  type        = string
  description = "Azure Container Registry resource ID used for AcrPull role assignment."
}

variable "acr_login_server" {
  type        = string
  description = "ACR login server, for example myregistry.azurecr.io."
}

variable "image_repository" {
  type        = string
  description = "ACR repository name."
  default     = "spring-petclinic"
}

variable "image_tag" {
  type        = string
  description = "Container image tag to deploy."
}

variable "feature_experimental_ui" {
  type        = string
  description = "Example secret-backed feature flag."
  default     = "false"
  sensitive   = true
}

variable "min_replicas" {
  type        = number
  description = "Minimum Container App replicas."
  default     = 1
}

variable "max_replicas" {
  type        = number
  description = "Maximum Container App replicas."
  default     = 2
}

variable "container_cpu" {
  type        = number
  description = "CPU assigned to the application container."
  default     = 0.5
}

variable "container_memory" {
  type        = string
  description = "Memory assigned to the application container."
  default     = "1Gi"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags."
  default     = {}
}
