output "alicloud_oidc_audience" {
    description = "OIDC audience used for GitHub Actions"
    value       = "sts.aliyuncs.com"
}

output "alicloud_oidc_provider_arn" {
    description = "The ARN of the GitHub OIDC provider"
    value       = alicloud_ims_oidc_provider.github.arn
}

output "alicloud_oidc_roles_to_assume" {
    description = "Map of GitHub Actions workflows to their assumed role ARNs"
    value = {
        for k, role in alicloud_ram_role.github_oidc_roles :
            k => role.arn
    }
}