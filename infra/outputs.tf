output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "acr_login_server" {
  value = azurerm_container_registry.main.login_server
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

output "static_site_default_host_name" {
  value = azurerm_static_site.frontend.default_host_name
}

output "security_service_app_id" {
  value = azuread_application.security_service_api.application_id
}

output "project_hub_app_id" {
  value = azuread_application.project_hub_api.application_id
}

output "spa_client_id" {
  value = azuread_application.project_hub_spa.application_id
}
