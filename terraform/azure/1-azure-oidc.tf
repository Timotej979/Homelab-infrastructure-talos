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
    for_each = {
        for repo_key, cfg in var.workload_identity_providers_config :
        repo_key => [
            for workflow_ref in length(cfg.workflow_ref_claims) > 0 ? cfg.workflow_ref_claims : [cfg.repository_claim] :
            {
                name                = "fid-${repo_key}-${replace(replace(workflow_ref, "/", "-"), "@", "-")}"
                subject             = "repo:${cfg.repository_claim}:ref:${cfg.ref_claim}${length(cfg.workflow_ref_claims) > 0 ? ":workflow:${element(split("@", workflow_ref), 0)}" : ""}"
                identity_key        = repo_key
            }
        ]
    }

    name                = each.value.name
    resource_group_name = azurerm_resource_group.oidc.name
    parent_id           = azurerm_user_assigned_identity.oidc_identity[each.value.identity_key].id
    audience            = ["api://AzureADTokenExchange"]
    issuer              = "https://token.actions.githubusercontent.com"
    subject             = each.value.subject
}