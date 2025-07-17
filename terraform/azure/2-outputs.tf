output "subscription_id" {
    description = "Azure Subscription ID"
    value       = var.azure_subscription_id
}

output "tenant_ids" {
    description = "Tenant IDs of each user-assigned identity"
    value = {
        for k, id in azurerm_user_assigned_identity.oidc_identity : 
            k => id.tenant_id
    }
}

output "oidc_client_ids" {
    description = "Map of identity client_ids per repo"
    value = {
        for k, id in azurerm_user_assigned_identity.oidc_identity : 
            k => id.client_id
    }
}