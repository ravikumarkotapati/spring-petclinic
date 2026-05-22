locals {
  normalized_prefix = lower(replace(var.name_prefix, "-", ""))
  acr_name          = var.acr_name != "" ? var.acr_name : "${local.normalized_prefix}${random_string.suffix.result}"
  common_tags = merge(
    {
      workload    = "spring-petclinic"
      module      = "module-6-cicd"
      environment = var.environment
    },
    var.tags
  )
}

resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

module "acr" {
  source = "../modules/acr"

  name                   = local.acr_name
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  sku                    = var.acr_sku
  acr_pull_principal_ids = var.acr_pull_principal_ids
  tags                   = local.common_tags
}
