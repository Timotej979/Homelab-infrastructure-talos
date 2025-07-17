# Define a local map for all the role definitions
locals {
    github_oidc_roles_map = {
        for k, config in var.workload_identity_providers_config : k => {
            for workflow_ref in config.workflow_ref_claims : "${k}-${basename(workflow_ref)}" => {
                name             = config.name
                actor_claim      = config.actor_claim
                repository_claim = config.repository_claim
                ref_claim        = config.ref_claim
                workflow_file    = split("/", split("@", workflow_ref)[0])[3]
            }
        }
    }
    flattened_roles = merge([
        for k, workflows in local.github_oidc_roles_map : workflows
    ]...)
}

# Fetch GitHub OIDC key
data "external" "github_oidc_key" {
  program = ["bash", "${path.module}/fetch_gh_oidc_key.sh"]
}

# Define an OIDC provider for GitHub Actions
resource "alicloud_ims_oidc_provider" "github" {
    oidc_provider_name  = "github-actions"
    description         = "OIDC provider for GitHub Actions"
    issuer_url          = "https://token.actions.githubusercontent.com"
    client_ids          = ["sts.aliyuncs.com"]
    fingerprints        = [data.external.github_oidc_key.result["fingerprints"]]
}

# Define the RAM policy document for GitHub OIDC roles
data "alicloud_ram_policy_document" "github_oidc" {
    for_each = local.flattened_roles

    statement {
        effect = "Allow"
        action = ["sts:AssumeRoleWithOIDC"]

        principal {
            entity = "Federated"
            identifiers = [alicloud_ims_oidc_provider.github.arn]
        }

        condition {
            operator = "StringEquals"
            variable = "oidc:aud"
            values   = ["sts.aliyuncs.com"]
        }

        condition {
            operator = "StringLike"
            variable = "oidc:sub"
            values   = ["repo:${each.value.repository_claim}:ref:${each.value.ref_claim}:workflow:${each.value.workflow_file}"]
        }
    }
}

# Define RAM roles for GitHub Actions workflows
resource "alicloud_ram_role" "github_oidc_roles" {
    for_each = local.flattened_roles
    role_name   = "${each.key}-role"
    description = "RAM role for GitHub Actions workflow ${each.key}"
    assume_role_policy_document = data.alicloud_ram_policy_document.github_oidc[each.key].document
    force       = true
}