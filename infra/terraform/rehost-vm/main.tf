data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

locals {
  normalized_workload = lower(replace(var.workload_name, "_", "-"))
  resource_token      = random_string.suffix.result

  vnet_name           = "${local.normalized_workload}-vnet"
  subnet_name         = "${local.normalized_workload}-app-snet"
  nsg_name            = "${local.normalized_workload}-app-nsg"
  public_ip_name      = "${local.normalized_workload}-pip"
  nic_name            = "${local.normalized_workload}-nic"
  vm_name             = "${local.normalized_workload}-vm"
  identity_name       = "${local.normalized_workload}-mi"
  key_vault_name      = substr(replace("${local.normalized_workload}${local.resource_token}kv", "-", ""), 0, 24)
  law_name            = "${local.normalized_workload}-${local.resource_token}-law"
  recovery_vault_name = "${local.normalized_workload}-${local.resource_token}-rsv"
  backup_policy_name  = "${local.normalized_workload}-daily-vm-policy"
  dcr_name            = "${local.normalized_workload}-vm-dcr"
  dns_label           = substr("${local.normalized_workload}-${local.resource_token}", 0, 63)
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_user_assigned_identity" "petclinic" {
  name                = local.identity_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

resource "azurerm_network_security_group" "app" {
  name                = local.nsg_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  security_rule {
    name                       = "Allow-HTTP-NGINX"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = var.http_source_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH-Admin"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_source_ip
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network" "main" {
  name                = local.vnet_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.40.0.0/16"]
  tags                = var.tags
}

resource "azurerm_subnet" "app" {
  name                 = local.subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.40.1.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}

resource "azurerm_public_ip" "app" {
  name                = local.public_ip_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = local.dns_label
  tags                = var.tags
}

resource "azurerm_network_interface" "app" {
  name                = local.nic_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.app.id
  }
}

resource "azurerm_key_vault" "petclinic" {
  name                          = local.key_vault_name
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  public_network_access_enabled = true
  soft_delete_retention_days    = 7
  purge_protection_enabled      = true
  tags                          = var.tags

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Recover",
      "Purge"
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.petclinic.principal_id

    secret_permissions = [
      "Get",
      "List"
    ]
  }
}

resource "azurerm_key_vault_secret" "active_profile" {
  name         = "petclinic-active-profile"
  value        = var.active_profile
  key_vault_id = azurerm_key_vault.petclinic.id
}

resource "azurerm_key_vault_secret" "datasource_url" {
  name         = "petclinic-datasource-url"
  value        = var.datasource_url
  key_vault_id = azurerm_key_vault.petclinic.id
}

resource "azurerm_key_vault_secret" "datasource_username" {
  name         = "petclinic-datasource-username"
  value        = var.datasource_username
  key_vault_id = azurerm_key_vault.petclinic.id
}

resource "azurerm_key_vault_secret" "datasource_password" {
  name         = "petclinic-datasource-password"
  value        = var.datasource_password
  key_vault_id = azurerm_key_vault.petclinic.id
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = local.law_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_monitor_data_collection_rule" "vm" {
  name                = local.dcr_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  destinations {
    log_analytics {
      name                  = "central-law"
      workspace_resource_id = azurerm_log_analytics_workspace.main.id
    }
  }

  data_sources {
    syslog {
      name = "linux-syslog"
      streams = [
        "Microsoft-Syslog"
      ]
      facility_names = [
        "auth",
        "authpriv",
        "cron",
        "daemon",
        "kern",
        "syslog",
        "user"
      ]
      log_levels = [
        "Warning",
        "Error",
        "Critical",
        "Alert",
        "Emergency"
      ]
    }

    performance_counter {
      name                          = "vm-performance"
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "\\Processor(_Total)\\% Processor Time",
        "\\Memory\\Available MBytes",
        "\\LogicalDisk(_Total)\\% Free Space"
      ]
    }
  }

  data_flow {
    streams = [
      "Microsoft-Syslog",
      "Microsoft-Perf"
    ]
    destinations = [
      "central-law"
    ]
  }
}

resource "azurerm_recovery_services_vault" "main" {
  name                = local.recovery_vault_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_backup_policy_vm" "daily" {
  name                = local.backup_policy_name
  resource_group_name = azurerm_resource_group.main.name
  recovery_vault_name = azurerm_recovery_services_vault.main.name

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 7
  }
}

resource "azurerm_linux_virtual_machine" "app" {
  name                            = local.vm_name
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.app.id]
  tags                            = var.tags

  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml.tftpl", {
    key_vault_uri      = trimsuffix(azurerm_key_vault.petclinic.vault_uri, "/")
    identity_client_id = azurerm_user_assigned_identity.petclinic.client_id
    app_port           = var.app_port
    repo_url           = var.repo_url
    repo_branch        = var.repo_branch
  }))

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.petclinic.id]
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  boot_diagnostics {}

  depends_on = [
    azurerm_key_vault_secret.active_profile,
    azurerm_key_vault_secret.datasource_url,
    azurerm_key_vault_secret.datasource_username,
    azurerm_key_vault_secret.datasource_password
  ]
}

resource "azurerm_virtual_machine_extension" "azure_monitor_agent" {
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.app.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  tags                       = var.tags
}

resource "azurerm_monitor_data_collection_rule_association" "vm" {
  name                    = "${local.vm_name}-dcr-association"
  target_resource_id      = azurerm_linux_virtual_machine.app.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.vm.id

  depends_on = [
    azurerm_virtual_machine_extension.azure_monitor_agent
  ]
}

resource "azurerm_backup_protected_vm" "app" {
  count               = var.enable_vm_backup ? 1 : 0
  resource_group_name = azurerm_resource_group.main.name
  recovery_vault_name = azurerm_recovery_services_vault.main.name
  source_vm_id        = azurerm_linux_virtual_machine.app.id
  backup_policy_id    = azurerm_backup_policy_vm.daily.id

  depends_on = [
    azurerm_linux_virtual_machine.app
  ]
}
