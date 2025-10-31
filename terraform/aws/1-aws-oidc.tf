# -------------------------------------------------
# Fetch GitHub OIDC Thumbprint dynamically via OpenSSL
# -------------------------------------------------
data "external" "github_oidc_thumbprint" {
    program = ["bash", "-c", <<EOT
        thumbprint=$(openssl s_client -servername token.actions.githubusercontent.com -connect token.actions.githubusercontent.com:443 </dev/null 2>/dev/null \
        | openssl x509 -fingerprint -noout -sha1 \
        | cut -d '=' -f 2 \
        | tr -d ':' \
        | tr '[:upper:]' '[:lower:]')
        jq -n --arg thumbprint "$thumbprint" '{"thumbprint":$thumbprint}'
    EOT
    ]
}

# -------------------------------------------------
# OIDC provider for GitHub Actions
# -------------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
    url            = "https://token.actions.githubusercontent.com"
    client_id_list = ["sts.amazonaws.com"]
    thumbprint_list = data.external.github_oidc_thumbprint.result["thumbprint"] != "" ? [data.external.github_oidc_thumbprint.result["thumbprint"]] : []
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
            test     = "StringLike"
            variable = "token.actions.githubusercontent.com:sub"
            values   = ["repo:${each.value.repository_claim}:environment:*"]
        }

        condition {
            test     = "StringEquals"
            variable = "token.actions.githubusercontent.com:aud"
            values   = ["sts.amazonaws.com"]
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
    # Describe Regions (Required for Packer AMI discovery)
    # Note: ec2:DescribeRegions does not support resource-level permissions
    # checkov:skip=CKV_AWS_107:ec2:DescribeRegions does not support resource-level permissions and is restricted by region condition
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:DescribeRegions"
        ]
        resources = ["*"]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    #########################
    # Describe AMIs (Required for Packer AMI discovery)
    # Note: ec2:DescribeImages does not support resource-level permissions
    # checkov:skip=CKV_AWS_107:ec2:DescribeImages does not support resource-level permissions and is restricted by region condition
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:DescribeImages",
            "ec2:DescribeImageAttribute"
        ]
        resources = ["*"]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
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
    # Describe VPCs/Subnets/KeyPairs
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:DescribeVpcs",
            "ec2:DescribeSubnets",
            "ec2:DescribeKeyPairs"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key-pair/*",
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:subnet/*",
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc/*"
        ]
    }

    #########################
    # Describe Security Groups
    # Note: ec2:DescribeSecurityGroups does not support resource-level permissions
    # checkov:skip=CKV_AWS_107:ec2:DescribeSecurityGroups does not support resource-level permissions and is restricted by region condition
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:DescribeSecurityGroups"
        ]
        resources = ["*"]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    #########################
    # EC2 KeyPair operations
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:CreateKeyPair",
            "ec2:DeleteKeyPair"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:key-pair/*"
        ]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
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
            "ec2:StartInstances",
            "ec2:RebootInstances",
            "ec2:DescribeInstanceStatus",
            "ec2:DescribeInstances",
            "ec2:GetConsoleOutput",
            "ec2:GetConsoleScreenshot"
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
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group/*",
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc/*"
        ]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    #########################
    # IAM permissions for EC2 instances
    #########################
    statement {
        effect = "Allow"
        actions = [
            "iam:PassRole"
        ]
        resources = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*"
        ]
        condition {
            test     = "StringEquals"
            variable = "iam:PassedToService"
            values   = ["ec2.amazonaws.com"]
        }
    }

    #########################
    # EC2 instance tagging operations
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:CreateTags",
            "ec2:DeleteTags"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*",
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:image/*",
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:snapshot/*",
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:volume/*"
        ]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    #########################
    # EC2 instance attribute operations
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:ModifyInstanceAttribute"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"
        ]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    #########################
    # EC2 describe operations
    # Note: These actions do not support resource-level permissions
    # checkov:skip=CKV_AWS_107:ec2:DescribeAvailabilityZones and ec2:DescribeAccountAttributes do not support resource-level permissions
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeAccountAttributes"
        ]
        resources = ["*"]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    #########################
    # EBS volume operations
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:CreateVolume",
            "ec2:DeleteVolume",
            "ec2:AttachVolume",
            "ec2:DetachVolume",
            "ec2:DescribeVolumes",
            "ec2:DescribeVolumeAttribute",
            "ec2:ModifyVolumeAttribute"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:volume/*"
        ]
        condition {
            test     = "StringEquals"
            variable = "aws:RequestedRegion"
            values   = [var.aws_region]
        }
    }

    #########################
    # EC2 Network interface operations
    #########################
    statement {
        effect = "Allow"
        actions = [
            "ec2:CreateNetworkInterface",
            "ec2:DeleteNetworkInterface",
            "ec2:AttachNetworkInterface",
            "ec2:DetachNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:ModifyNetworkInterfaceAttribute",
            "ec2:AssociateAddress",
            "ec2:DisassociateAddress",
            "ec2:AllocateAddress",
            "ec2:ReleaseAddress",
            "ec2:DescribeAddresses"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:network-interface/*",
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:elastic-ip/*"
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
            "ec2:DescribeImages",
            "ec2:DescribeImageAttribute",
            "ec2:CreateTags",
            "ec2:DeleteTags"
        ]
        resources = [
            "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:image/*"
        ]
        condition {
            test     = "StringLike"
            variable = "ec2:ImageName"
            values   = ["talos-*"]
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