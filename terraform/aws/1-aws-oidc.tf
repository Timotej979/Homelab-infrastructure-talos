# -------------------------------------------------
# OIDC provider for GitHub Actions
# -------------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
    url            = "https://token.actions.githubusercontent.com"
    client_id_list = ["https://github.com/${values(var.workload_identity_providers_config)[0].actor_claim}"]
}

# -------------------------------------------------
# Trust policy for GitHub OIDC roles
# -------------------------------------------------
data "aws_iam_policy_document" "github_oidc" {
    for_each = var.workload_identity_providers_config

    statement {
        effect  = "Allow"
        actions = ["sts:AssumeRoleWithWebIdentity"]

        principals {
            type        = "Federated"
            identifiers = [aws_iam_openid_connect_provider.github.arn]
        }

        condition {
            test     = "StringEquals"
            variable = "token.actions.githubusercontent.com:actor"
            values   = [each.value.actor_claim]
        }

        condition {
            test     = "StringEquals"
            variable = "token.actions.githubusercontent.com:repository"
            values   = [each.value.repository_claim]
        }

        condition {
        test     = "StringEquals"
        variable = "token.actions.githubusercontent.com:ref"
        values   = [each.value.ref_claim]
        }

        condition {
            test     = "StringEquals"
            variable = "token.actions.githubusercontent.com:workflow_ref"
            values   = each.value.workflow_ref_claims
        }

        condition {
            test     = "StringLike"
            variable = "token.actions.githubusercontent.com:sub"
            values   = ["repo:${each.value.repository_claim}:*"]
        }
    }
}

# -------------------------------------------------
# Minimal Packer Talos policy for Packer Talos
# -------------------------------------------------
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "packer_talos" {
    for_each = var.workload_identity_providers_config

    #########################
    # Describe Instances
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:DescribeInstances",
            "ec2:DescribeInstanceStatus"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"
        ]
    }

    #########################
    # Describe AMIs
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:DescribeImages",
            "ec2:DescribeImageAttribute"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:image/*"
        ]
    }

    #########################
    # Describe Snapshots
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:DescribeSnapshots",
            "ec2:DescribeSnapshotAttribute"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:snapshot/*"
        ]
    }

    #########################
    # Describe VPCs/Subnets/SGs/KeyPairs
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:DescribeVpcs",
            "ec2:DescribeSubnets",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeKeyPairs"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key-pair/*",
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group/*",
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:subnet/*",
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc/*"
        ]
    }

    #########################
    # EC2 instance operations
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:RunInstances",
            "ec2:TerminateInstances",
            "ec2:StopInstances",
            "ec2:StartInstances"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"
        ]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
        condition {
            test     = "StringEquals"
            variable = "ec2:InstanceType"
            values   = each.value.allowed_ec2_instance_types
        }
    }

    #########################
    # Security group operations
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:CreateSecurityGroup",
            "ec2:DeleteSecurityGroup",
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:RevokeSecurityGroupIngress"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group/*"
        ]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    #########################
    # AMI operations
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:CreateImage",
            "ec2:RegisterImage",
            "ec2:DeregisterImage",
            "ec2:ModifyImageAttribute",
            "ec2:CreateTags",
            "ec2:DeleteTags"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:image/*"
        ]
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

    #########################
    # Snapshot operations
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:CreateSnapshot",
            "ec2:DeleteSnapshot",
            "ec2:ModifySnapshotAttribute",
            "ec2:CreateTags",
            "ec2:DeleteTags"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:snapshot/*"
        ]
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
    for_each           = var.workload_identity_providers_config
    name               = "${each.key}-role"
    description        = "IAM role for GitHub Actions workflow ${each.key}"
    assume_role_policy = data.aws_iam_policy_document.github_oidc[each.key].json
}

# Attach the Packer Talos policy to each OIDC role
resource "aws_iam_role_policy" "packer_talos_policy" {
    for_each   = var.workload_identity_providers_config
    role       = aws_iam_role.github_oidc_roles[each.key].id
    policy     = data.aws_iam_policy_document.packer_talos[each.key].json
}