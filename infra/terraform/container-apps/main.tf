locals {
  app_image = "${var.acr_login_server}/${var.image_repository}:${var.image_tag}"

  common_tags = merge(
    {
      workload    = "spring-petclinic"
      module      = "module-7-replatform"
      environment = var.environment
      target      = "azure-container-apps"
    },
    var.tags
  )
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.name_prefix}-law"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

resource "azurerm_container_app_environment" "main" {
  name                       = "${var.name_prefix}-env"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  tags                       = local.common_tags
}

resource "azurerm_user_assigned_identity" "container_app" {
  name                = "${var.name_prefix}-mi"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.container_app.principal_id
}

resource "azurerm_container_app" "petclinic" {
  name                         = var.container_app_name
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  tags                         = local.common_tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.container_app.id]
  }

  registry {
    server   = var.acr_login_server
    identity = azurerm_user_assigned_identity.container_app.id
  }

  secret {
    name  = "feature-experimental-ui"
    value = var.feature_experimental_ui
  }

  ingress {
    external_enabled = true
    target_port      = 8081
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = "spring-petclinic"
      image  = local.app_image
      cpu    = var.container_cpu
      memory = var.container_memory

      env {
        name  = "SERVER_PORT"
        value = "8081"
      }

      env {
        name  = "SPRING_PROFILES_ACTIVE"
        value = "default"
      }

      env {
        name  = "MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE"
        value = "health,info"
      }

      env {
        name        = "PETCLINIC_FEATURE_EXPERIMENTAL_UI"
        secret_name = "feature-experimental-ui"
      }

      env {
        name  = "JAVA_OPTS"
        value = "-XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"
      }
    }
  }

  depends_on = [
    azurerm_role_assignment.acr_pull
  ]
}
