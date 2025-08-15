# -------------------------------------------------
# Local map for role definitions
# -------------------------------------------------
locals {
  github_oidc_roles_map = {
    for k, config in var.workload_identity_providers_config : k => {
      for workflow_ref in config.workflow_ref_claims : "${k}-${basename(workflow_ref)}" => {
        name             = config.name
        actor_claim      = config.actor_claim
        repository_claim = config.repository_claim
        ref_claim        = config.ref_claim
        workflow_file    = basename(split("@", workflow_ref)[0])
      }
    }
  }
  flattened_roles = merge([
    for k, workflows in local.github_oidc_roles_map : workflows
  ]...)
}

# -------------------------------------------------
# OIDC provider for GitHub Actions
# -------------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# -------------------------------------------------
# Trust policy for GitHub OIDC roles
# -------------------------------------------------
data "aws_iam_policy_document" "github_oidc" {
  for_each = local.flattened_roles

  statement {
    effect  = "Allow"
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
      values   = ["repo:${each.value.repository_claim}:ref:${each.value.ref_claim}:workflow:${each.value.workflow_file}"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:actor"
      values   = [each.value.actor_claim]
    }
  }
}

# -------------------------------------------------
# Minimal Packer Talos policy for Packer Talos
# -------------------------------------------------
data "aws_iam_policy_document" "packer_talos" {
  # Describe calls - still global
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeImages",
      "ec2:DescribeImageAttribute",
      "ec2:DescribeSnapshots",
      "ec2:DescribeSnapshotAttribute",
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeKeyPairs"
    ]
    resources = ["*"]
  }

  # Run and terminate instances in eu-central-1, only t4g.medium
  statement {
    effect = "Allow"
    actions = [
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ec2:StopInstances",
      "ec2:StartInstances"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:InstanceType"
      values   = ["t4g.medium"]
    }
  }

  # Temporary SG creation/deletion in eu-central-1
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  # AMI and snapshot management - only for Talos AMIs
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateImage",
      "ec2:RegisterImage",
      "ec2:DeregisterImage",
      "ec2:ModifyImageAttribute",
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot",
      "ec2:ModifySnapshotAttribute",
      "ec2:CreateTags",
      "ec2:DeleteTags"
    ]
    resources = ["*"]

    # Only allow AMI names starting with talos-system-disk-
    condition {
      test     = "StringLike"
      variable = "ec2:ImageName"
      values   = ["talos-system-disk-*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }
}

# -------------------------------------------------
# IAM roles for GitHub OIDC (trust policy + packer policy)
# -------------------------------------------------
resource "aws_iam_role" "github_oidc_roles" {
  for_each           = local.flattened_roles
  name               = "${each.key}-role"
  description        = "IAM role for GitHub Actions workflow ${each.key}"
  assume_role_policy = data.aws_iam_policy_document.github_oidc[each.key].json
}

# Attach the Packer Talos policy to each OIDC role
resource "aws_iam_role_policy" "packer_talos_policy" {
  for_each   = local.flattened_roles
  role       = aws_iam_role.github_oidc_roles[each.key].id
  policy     = data.aws_iam_policy_document.packer_talos.json
}
