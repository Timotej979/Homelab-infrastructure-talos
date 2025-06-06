output "oidc_client_ids" {
  description = "Map of identity client_ids per repo"
  value = {
    for k, id in azurerm_user_assigned_identity.oidc_identity :
    k => id.client_id
  }
}

output "tenant_id" {
  value       = var.azure_tenant_id
  description = "Azure Tenant ID"
}

output "subscription_id" {
  value       = var.azure_subscription_id
  description = "Azure Subscription ID"
}