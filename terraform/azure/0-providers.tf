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
}