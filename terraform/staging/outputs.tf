output "acr_login_server" {
  description = "Shared Prod ACR Login Server"
  value       = data.azurerm_container_registry.prod_acr.login_server
}

output "storage_account_name" {
  description = "Staging Storage Account Name"
  value       = azurerm_storage_account.storage.name
}

output "aks_name" {
  description = "Staging AKS name"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "resource_group_name" {
  description = "Staging resource group"
  value       = azurerm_resource_group.staging_rg.name
}
