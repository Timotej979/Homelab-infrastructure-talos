resource "google_iam_workload_identity_pool" "github_actions" {
    workload_identity_pool_id = "github-actions"
    display_name              = "GitHub Actions"
    description               = "Workload Identity Pool for GitHub Actions"
    disabled                  = false
}

resource "google_iam_workload_identity_pool_provider" "github_actions_provider" {
    for_each = var.workload_identity_providers_config

    workload_identity_pool_provider_id = "${each.value.name}-wip"
    workload_identity_pool_id          =  google_iam_workload_identity_pool.github_actions.workload_identity_pool_id
    display_name                       = "${each.value.name} Workload Identity Provider"
    description                        = "Workload Identity Provider for ${each.value.name} GitHub Actions"
    disabled                           = false

    oidc {
        issuer_uri = "https://token.actions.githubusercontent.com"
    }

    attribute_condition = <<EOT
        attribute.actor == "${each.value.actor_claim}" &&
        attribute.repository == "${each.value.repository_claim}" &&
        assertion.ref == "${each.value.ref_claim}" &&
        assertion.workflow_ref in [
            ${join(", ", [for ref in each.value.workflow_ref_claims : "\"${ref}\""])}
        ]
    EOT

    attribute_mapping = {
        "google.subject"       = "assertion.sub"
        "attribute.actor"      = "assertion.actor"
        "attribute.aud"        = "assertion.aud"
        "attribute.repository" = "assertion.repository"
        "attribute.ref"        = "assertion.ref"
        "attribute.workflow_ref" = "assertion.workflow_ref"
    }
}