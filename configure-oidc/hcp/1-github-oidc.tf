# Define the service principal (replace if one already exists)
resource "hcp_service_principal" "oidc_deployment_sp" {
    for_each = var.workload_identity_providers_config

    name = "${each.value.name}"
    parent = "projects/${var.hcp_project_id}"
}

# Create workload identity provider for GitHub Actions
resource "hcp_iam_workload_identity_provider" "github_wip" {
    for_each = var.workload_identity_providers_config

    name              = "${each.value.name}-wip"
    service_principal = hcp_service_principal.oidc_deployment_sp[each.key].resource_name
    description       = "Allow GitHub Actions from ${each.value.repository_claim} repository on ${each.value.ref_claim} branch to authenticate with HCP"

    oidc {
        issuer_uri = "https://token.actions.githubusercontent.com"
    }

    conditional_access = <<EOT
        jwt.actor == "${each.value.actor_claim}" and
        jwt_claims.repository == "${each.value.repository_claim}" and
        jwt_claims.ref == "${each.value.ref_claim}" and
        jwt_claims.workflow_ref in [
            ${join(", ", [for ref in each.value.workflow_ref_claims : "\"${ref}\""])}
        ]
    EOT
}