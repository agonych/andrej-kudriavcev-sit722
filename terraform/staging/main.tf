# Reuse prod Resource Group
data "azurerm_resource_group" "prod_rg" {
  name = "${var.prefixprod}rg"
}

# Reuse prod ACR
data "azurerm_container_registry" "prod_acr" {
  name                = "${var.prefixprod}acr"
  resource_group_name = data.azurerm_resource_group.prod_rg.name
}

# Create staging Resource Group
resource "azurerm_resource_group" "staging_rg" {
  name     = "${var.prefix}rg"
  location = var.location
}

# Create Staging AKS cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.prefix}aks"
  location            = azurerm_resource_group.staging_rg.location
  resource_group_name = azurerm_resource_group.staging_rg.name
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

# Allow staging AKS to pull images from prod ACR
resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = data.azurerm_container_registry.prod_acr.id

  skip_service_principal_aad_check = true

  depends_on = [azurerm_kubernetes_cluster.aks]

  lifecycle {
    ignore_changes = [skip_service_principal_aad_check]
  }
}

# Create Staging storage account
resource "azurerm_storage_account" "storage" {
  name                     = "${var.prefix}storage"
  resource_group_name      = azurerm_resource_group.staging_rg.name
  location                 = azurerm_resource_group.staging_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create blob container in staging storage account
resource "azurerm_storage_container" "images" {
  name                  = "images"
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "blob"
}
