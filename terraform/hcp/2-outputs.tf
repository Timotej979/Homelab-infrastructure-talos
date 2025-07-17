output "service_principal_name" {
  value = [for sp in values(hcp_service_principal.oidc_deployment_sp) : sp.resource_name]
}

output "workload_identity_provider_id" {
  value = [for wip in values(hcp_iam_workload_identity_provider.github_wip) : wip.resource_id]
}

output "workload_identity_provider_name" {
  value = [for wip in values(hcp_iam_workload_identity_provider.github_wip) : wip.resource_name]
}