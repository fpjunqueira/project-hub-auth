resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "main" {
  name                = "${var.project_name}-appinsights"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.main.id
}

resource "azurerm_key_vault" "main" {
  name                        = "${var.project_name}-kv"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
  soft_delete_retention_days  = 7
}

resource "azurerm_container_registry" "main" {
  name                = "${var.project_name}acr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  admin_enabled       = false
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "aks" {
  name                 = "aks"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.project_name}-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.project_name}-aks"

  default_node_pool {
    name            = "system"
    node_count      = var.aks_node_count
    vm_size         = var.aks_vm_size
    vnet_subnet_id  = azurerm_subnet.aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  network_profile {
    network_plugin = "azure"
  }
}

resource "azurerm_static_site" "frontend" {
  name                = "${var.project_name}-frontend"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_tier            = "Standard"
  sku_size            = "Standard"
}

data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}

resource "random_uuid" "security_scope" {}
resource "random_uuid" "project_hub_scope" {}

resource "azuread_application" "security_service_api" {
  display_name     = "${var.project_name}-security-service-api"
  identifier_uris  = [var.security_service_identifier_uri]
  sign_in_audience = "AzureADMyOrg"

  api {
    oauth2_permission_scope {
      admin_consent_description  = "Access security-service API"
      admin_consent_display_name = "Access security-service"
      enabled                    = true
      id                         = random_uuid.security_scope.result
      type                       = "User"
      user_consent_description   = "Access security-service API"
      user_consent_display_name  = "Access security-service"
      value                      = "access_as_user"
    }
  }
}

resource "azuread_service_principal" "security_service_api" {
  application_id = azuread_application.security_service_api.application_id
}

resource "azuread_application" "project_hub_api" {
  display_name     = "${var.project_name}-project-hub-api"
  identifier_uris  = [var.project_hub_identifier_uri]
  sign_in_audience = "AzureADMyOrg"

  api {
    oauth2_permission_scope {
      admin_consent_description  = "Access project-hub API"
      admin_consent_display_name = "Access project-hub"
      enabled                    = true
      id                         = random_uuid.project_hub_scope.result
      type                       = "User"
      user_consent_description   = "Access project-hub API"
      user_consent_display_name  = "Access project-hub"
      value                      = "access_as_user"
    }
  }
}

resource "azuread_service_principal" "project_hub_api" {
  application_id = azuread_application.project_hub_api.application_id
}

resource "azuread_application" "project_hub_spa" {
  display_name     = "${var.project_name}-spa"
  sign_in_audience = "AzureADMyOrg"

  spa {
    redirect_uris = var.spa_redirect_uris
  }

  required_resource_access {
    resource_app_id = azuread_application.project_hub_api.application_id
    resource_access {
      id   = random_uuid.project_hub_scope.result
      type = "Scope"
    }
  }

  required_resource_access {
    resource_app_id = azuread_application.security_service_api.application_id
    resource_access {
      id   = random_uuid.security_scope.result
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "project_hub_spa" {
  application_id = azuread_application.project_hub_spa.application_id
}
