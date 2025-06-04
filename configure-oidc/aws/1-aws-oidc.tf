# OIDC provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github" {
    url             = "https://token.actions.githubusercontent.com"
    client_id_list  = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "github_oidc_roles" {
    for_each = {
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

    name = "${each.key}-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = {
                Federated = aws_iam_openid_connect_provider.github.arn
            }
            Action = "sts:AssumeRoleWithWebIdentity"
            Condition = {
                StringEquals = {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
                    "token.actions.githubusercontent.com:sub" = "repo:${each.value.repository_claim}:ref:${each.value.ref_claim}:workflow:${each.value.workflow_file}"
                    "token.actions.githubusercontent.com:actor" = each.value.actor_claim
                }
            }   
        }]
    })
}