variable "subscription_id" {
  description = "Azure subscription ID used by the AzureRM provider."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for the rehosted VM landing pattern."
  type        = string
  default     = "rg-petclinic-rehost-dev"
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus"
}

variable "workload_name" {
  description = "Short workload name used as a resource name prefix."
  type        = string
  default     = "petclinic-rehost"
}

variable "admin_username" {
  description = "Linux admin username for SSH access."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key used for Linux admin access."
  type        = string
}

variable "admin_source_ip" {
  description = "CIDR allowed to reach SSH. Use your public IP with /32 for least privilege."
  type        = string

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.admin_source_ip))
    error_message = "admin_source_ip must be CIDR format, for example 101.100.182.17/32."
  }
}

variable "http_source_ip" {
  description = "CIDR allowed to reach public HTTP ingress. Use 0.0.0.0/0 for evaluator access or your public IP /32 for least privilege."
  type        = string
  default     = "0.0.0.0/0"
}

variable "vm_size" {
  description = "Azure VM size."
  type        = string
  default     = "Standard_B2ms"
}

variable "repo_url" {
  description = "Git repository URL cloned by cloud-init on first boot."
  type        = string
  default     = "https://github.com/ravikumarkotapati/spring-petclinic.git"
}

variable "repo_branch" {
  description = "Git branch cloned by cloud-init on first boot."
  type        = string
  default     = "module4-rehost-azure-vm"
}

variable "app_port" {
  description = "Internal Spring Boot app port. NGINX listens on 80 and proxies to this port."
  type        = number
  default     = 8081
}

variable "active_profile" {
  description = "Spring active profile stored in Key Vault. Use h2 for smoke testing or postgres/mysql for an external DB endpoint."
  type        = string
  default     = "h2"

  validation {
    condition     = contains(["h2", "postgres", "mysql"], var.active_profile)
    error_message = "active_profile must be h2, postgres, or mysql."
  }
}

variable "datasource_url" {
  description = "Spring datasource JDBC URL stored in Key Vault. Use not-configured for h2 smoke tests."
  type        = string
  default     = "not-configured"
  sensitive   = true
}

variable "datasource_username" {
  description = "Spring datasource username stored in Key Vault. Use not-configured for h2 smoke tests."
  type        = string
  default     = "not-configured"
  sensitive   = true
}

variable "datasource_password" {
  description = "Spring datasource password stored in Key Vault. Use not-configured for h2 smoke tests."
  type        = string
  default     = "not-configured"
  sensitive   = true
}

variable "enable_vm_backup" {
  description = "Enable Azure Backup protection for the VM."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to Azure resources."
  type        = map(string)
  default = {
    workload    = "spring-petclinic"
    module      = "module-4-rehost"
    environment = "dev"
  }
}
