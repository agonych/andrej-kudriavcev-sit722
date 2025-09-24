output "acr_login_server" {
  description = "ACR Login Server URL"
  value       = azurerm_container_registry.acr.login_server
}

output "storage_account_name" {
  description = "Storage Account Name"
  value       = azurerm_storage_account.storage.name
}

output "aks_kube_config" {
  description = "Kube config for AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "storage_account_key" {
  description = "Storage Account Key"
  value       = azurerm_storage_account.storage.primary_access_key
  sensitive   = true
}

output "resource_group_name" {
  description = "Resource group where infra is deployed"
  value       = azurerm_resource_group.rg.name
}

output "aks_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}