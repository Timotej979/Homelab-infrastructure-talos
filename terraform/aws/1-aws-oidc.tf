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
  # Flatten nested maps into a single map
  flattened_roles = merge([
    for k, workflows in local.github_oidc_roles_map : workflows
  ]...)
}

# Define the OIDC provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# Define the IAM policy document for GitHub OIDC roles
data "aws_iam_policy_document" "github_oidc" {
  for_each = local.flattened_roles

  statement {
    effect = "Allow"

    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [
        "repo:${each.value.repository_claim}:ref:${each.value.ref_claim}:workflow:${each.value.workflow_file}"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:actor"
      values   = [each.value.actor_claim]
    }
  }
}

# Define the IAM roles for GitHub OIDC
resource "aws_iam_role" "github_oidc_roles" {
  for_each = local.flattened_roles

  name = "${each.key}-role"
  description = "IAM role for GitHub Actions workflow ${each.key}"
  assume_role_policy = data.aws_iam_policy_document.github_oidc[each.key].json
}