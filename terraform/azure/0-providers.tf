terraform {
    required_version = ">= 1.12.0"
  
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = ">= 3.0"
        }
    }
}

provider "azurerm" {
    features {}
    subscription_id = var.azure_subscription_id
    tenant_id       = var.azure_tenant_id
    client_id       = var.azure_client_id
    client_secret   = var.azure_client_secret
}