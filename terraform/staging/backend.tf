terraform {
  backend "azurerm" {
    resource_group_name  = "sit722akprodrg"
    storage_account_name = "sit722akprodstorage"
    container_name       = "tfstate"
    key                  = "staging.terraform.tfstate"
  }
}