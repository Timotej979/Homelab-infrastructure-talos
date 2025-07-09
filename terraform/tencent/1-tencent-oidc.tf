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

# Fetch GitHub OIDC key
data "external" "github_oidc_key" {
  program = ["bash", "${path.module}/fetch_github_oidc_key.sh"]
}

# Define an OIDC provider for GitHub Actions
resource "tencentcloud_cam_oidc_sso" "github" {
  authorization_endpoint = "https://token.actions.githubusercontent.com"
  identity_url           = "https://token.actions.githubusercontent.com"
  client_id              = "sts.tencentcloudapi.com"

  response_type = "id_token"
  response_mode = "form_post"

  identity_key  = data.external.github_key.result.github_oidc_base64_key
  mapping_filed = "sub"
  scope         = ["openid"]
}

resource "tencentcloud_cam_role" "github_roles" {
  for_each = local.flattened_roles

  name        = "${each.key}-role"
  description = "OIDC CAM role for ${each.key}"
  document    = jsonencode({
    version = "2.0"
    statement = [
      {
        effect   = "Allow"
        action   = ["name/sts:AssumeRoleWithOIDC"]
        principal = {
          federated = tencentcloud_cam_oidc_sso.github.id
        }
        condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.tencentcloudapi.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${each.value.repository_claim}:ref:${each.value.ref_claim}:workflow:${each.value.workflow_file}"
          }
        }
      }
    ]
  })
}