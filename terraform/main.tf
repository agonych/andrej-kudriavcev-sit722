resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}rg"
  location = var.location
}

resource "azurerm_container_registry" "acr" {
  name                = "${var.prefix}acr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.prefix}aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.prefix
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2s_v3"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true

  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}

resource "azurerm_storage_account" "storage" {
  name                     = "${var.prefix}storage"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "images" {
  name                     = "images"
  storage_account_id       = azurerm_storage_account.storage.id
  container_access_type    = "blob"
}

output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}

output "storage_account_key" {
  value     = azurerm_storage_account.storage.primary_access_key
  sensitive = true
}