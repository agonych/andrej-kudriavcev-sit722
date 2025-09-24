terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  use_oidc        = var.client_secret == "" ? true : false
  subscription_id = var.subscription_id != "" ? var.subscription_id : null
  tenant_id       = var.tenant_id       != "" ? var.tenant_id       : null
  client_id       = var.client_id       != "" ? var.client_id       : null
  client_secret   = var.client_secret   != "" ? var.client_secret   : null
}
