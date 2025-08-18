# Fetch the HCP project details
data "hcp_project" "this" {
  project = "project/${var.hcp_project_id}"
}

# Define the service principal (replace if one already exists)
resource "hcp_service_principal" "oidc_deployment_sp" {
    for_each = var.workload_identity_providers_config

    name   = each.value.name
    parent = data.hcp_project.this.resource_name
}

# Create a HCP project IAM role binding
resource "hcp_project_iam_binding" "oidc_deployment_sp_binding" {
    for_each = var.workload_identity_providers_config

    principal_id = hcp_service_principal.oidc_deployment_sp[each.key].resource_id
    role         = each.value.hcp_role
}

# Create workload identity provider for GitHub Actions
resource "hcp_iam_workload_identity_provider" "github_wip" {
    for_each = var.workload_identity_providers_config

    name              = "${each.value.name}-wip"
    service_principal = hcp_service_principal.oidc_deployment_sp[each.key].resource_name
    description       = "Allow GitHub Actions from ${each.value.repository_claim} repository on ${each.value.ref_claim} branch to authenticate with HCP"

    oidc = {
        issuer_uri = "https://token.actions.githubusercontent.com"
    }

    conditional_access = <<EOT
        jwt.claim["actor"] == "${each.value.actor_claim}" and
        jwt.claim["repository"] == "${each.value.repository_claim}" and
        jwt.claim["sub"] != "" and
        (
        ${join(" or ", [for wf in each.value.workflow_ref_claims : "jwt.claim[\"workflow\"] == \"${wf}\""])}
        )
    EOT
}