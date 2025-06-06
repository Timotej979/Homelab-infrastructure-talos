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
        for _, workflows in local.github_oidc_roles_map : workflows
    ]...)
}

# Define an OIDC provider for GitHub Actions
resource "tencentcloud_cam_oidc_provider" "github" {
    name        = "github-actions"
    description = "OIDC provider for GitHub Actions"
    url         = "https://token.actions.githubusercontent.com"
    identity_url = "https://token.actions.githubusercontent.com"
    client_id_list = ["sts.tencentcloudapi.com"]
}

# Trust policy documents for each GitHub workflow
data "tencentcloud_cam_role_policy_document" "github_oidc" {
    for_each = local.flattened_roles

    statement {
        effect = "Allow"
        action = ["name/sts:AssumeRoleWithOIDC"]

        principal {
            type        = "Federated"
            identifiers = [tencentcloud_cam_oidc_provider.github.id]
        }

        condition {
            test     = "StringEquals"
            variable = "token.actions.githubusercontent.com:aud"
            values   = ["sts.tencentcloudapi.com"]
        }

        condition {
            test     = "StringLike"
            variable = "token.actions.githubusercontent.com:sub"
            values   = ["repo:${each.value.repository_claim}:ref:${each.value.ref_claim}:workflow:${each.value.workflow_file}"]
        }
    }
}

# Role definitions
resource "tencentcloud_cam_role" "github_oidc_roles" {
    for_each = local.flattened_roles
    name        = "${each.key}-role"
    description = "CAM role for GitHub Actions workflow ${each.key}"
    document    = data.tencentcloud_cam_role_policy_document.github_oidc[each.key].json
}
