output "service_principal_name" {
    value = hcp_service_principal.oidc_deployment_sp[*].resource_name
}

output "workload_identity_provider_id" {
    value = hcp_iam_workload_identity_provider.github_wip[*].resource_id
}

output "workload_identity_provider_name" {
    value = hcp_iam_workload_identity_provider.github_wip[*].resource_name
}