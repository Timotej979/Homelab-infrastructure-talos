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
        assertion.actor == "${try(each.value.actor_claim, "Timotej979")}" &&
        assertion.repository == "${try(each.value.repository_claim, "Timotej979/Homelab-infrastructure-talos")}" &&
        assertion.ref == "${try(each.value.ref_claim, "refs/heads/main")}" &&
        assertion.workflow_ref in [
            ${join(", ", [for ref in each.value.workflow_ref_claims : "\"${try(ref, "Timotej979/Homelab-infrastructure-talos/.github/workflows/build-gcp.yml@refs/heads/main")}\""])}
        ]
    EOT

    attribute_mapping = {
        "google.subject"         = "assertion.sub"
        "assertion.actor"        = "assertion.actor"
        "assertion.aud"          = "assertion.aud"
        "assertion.repository"   = "assertion.repository"
        "assertion.ref"          = "assertion.ref"
        "assertion.workflow_ref" = "assertion.workflow_ref"
    }
}