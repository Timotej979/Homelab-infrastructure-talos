locals {
  github_actions_providers = merge(
    [
        for k, config in var.workload_identity_providers_config : {
            for workflow_ref in config.workflow_ref_claims : "${k}-${basename(workflow_ref)}" => {
                name                = config.name
                actor_claim         = config.actor_claim
                repository_claim    = config.repository_claim
                ref_claim           = config.ref_claim
                workflow_file       = split("/", split("@", workflow_ref)[0])[3]
                attribute_condition = "assertion.sub == \"repo:${config.repository_claim}:ref:${config.ref_claim}:workflow:${split("/", split("@", workflow_ref)[0])[3]}\""
            }
        }
    ]...
  )
}

resource "google_iam_workload_identity_pool" "github_actions" {
    workload_identity_pool_id = "github-actions"
    display_name              = "GitHub Actions"
    description               = "Workload Identity Pool for GitHub Actions"
    disabled                  = false
}

resource "google_iam_workload_identity_pool_provider" "github_actions_provider" {
  for_each = local.github_actions_providers

  workload_identity_pool_provider_id = "${each.value.name}-wip"
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_actions.workload_identity_pool_id
  display_name                       = "${each.value.name} Workload Identity Provider"
  description                        = "Workload Identity Provider for ${each.value.name} GitHub Actions"
  disabled                           = false

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_condition = each.value.attribute_condition

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }
}
