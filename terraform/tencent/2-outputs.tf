output "tencent_oidc_audience" {
    description = "OIDC audience used for GitHub Actions"
    value       = "sts.tencentcloudapi.com"
}

output "tencent_region" {
    description = "Region where the OIDC provider is created"
    value       = var.tencent_region
}

output "tencent_oidc_provider_arn" {
    description = "The ARN of the GitHub OIDC provider"
    value       = tencent_iam_oidc_provider.github.arn
}

output "tencent_oidc_roles_to_assume" {
    description = "Map of GitHub Actions workflows to their assumed role ARNs"
    value = {
        for k, role in tencent_iam_role.github_oidc_roles :
            k => role.arn
    }
}