output "tencent_oidc_audience" {
  description = "OIDC audience used for GitHub Actions"
  value       = "sts.tencentcloudapi.com"
}

output "tencent_oidc_provider_id" {
  description = "The ID of the Tencent CAM OIDC SSO provider"
  value       = tencentcloud_cam_oidc_sso.github.id
}

output "tencent_oidc_roles_to_assume" {
  description = "Map of GitHub Actions workflows to their assumed CAM role ARNs"
  value = {
    for k, role in tencentcloud_cam_role.github_roles :
    k => role.arn
  }
}