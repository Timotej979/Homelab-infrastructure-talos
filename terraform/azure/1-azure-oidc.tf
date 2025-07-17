# Define a local map for all the role definitions 
locals {
  flattened_oidc_credentials = merge([
    for key, config in var.workload_identity_providers_config : {
      for workflow_ref in config.workflow_ref_claims : 
      "${key}-${replace(basename(workflow_ref), ".", "-")}" => {
        identity_key       = key
        name               = config.name
        actor_claim        = config.actor_claim
        repository_claim   = config.repository_claim
        ref_claim          = config.ref_claim
        workflow_ref       = workflow_ref
        workflow_file      = basename(split("@", workflow_ref)[0])
      }
    }
  ]...)
}

# Define the resource group for OIDC identities
resource "azurerm_resource_group" "oidc" {
    name     = "rg-oidc-identities"
    location = var.azure_region
}

# Define User Assigned Identities for OIDC
resource "azurerm_user_assigned_identity" "oidc_identity" {
    for_each            = var.workload_identity_providers_config
    name                = "id-${each.value.name}"
    location            = var.azure_region
    resource_group_name = azurerm_resource_group.oidc.name
}

# Define Role Assignments for User Assigned Identities
resource "azurerm_role_assignment" "role" {
    for_each             = var.workload_identity_providers_config
    scope                = azurerm_resource_group.oidc.id
    role_definition_name = "Contributor"
    principal_id         = azurerm_user_assigned_identity.oidc_identity[each.key].principal_id
}

# Define Federated Identity Credentials for OIDC
resource "azurerm_federated_identity_credential" "fid" {
  for_each = local.flattened_oidc_credentials

  name                = "fid-${each.key}"
  resource_group_name = azurerm_resource_group.oidc.name
  parent_id           = azurerm_user_assigned_identity.oidc_identity[each.value.identity_key].id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:${each.value.repository_claim}:ref:${each.value.ref_claim}:workflow:${each.value.workflow_file}"
}
