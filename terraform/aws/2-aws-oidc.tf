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
# IAM roles for GitHub OIDC (trust policy + build policy)
# -------------------------------------------------
resource "aws_iam_role" "github_oidc_roles" {
    for_each           = var.workload_identity_providers_config
    name               = "${each.key}-role"
    description        = "IAM role for GitHub Actions workflow ${each.key}"
    assume_role_policy = data.aws_iam_policy_document.github_oidc[each.key].json
}

# Attach the build policy to each OIDC role
resource "aws_iam_role_policy" "packer_talos_policy" {
    for_each   = var.workload_identity_providers_config
    role       = aws_iam_role.github_oidc_roles[each.key].id
    policy     = data.aws_iam_policy_document.packer_talos[each.key].json
}