output "hcp_oidc_auth" {
  value = {
    for k, sp in hcp_service_principal.oidc_deployment_sp :
    k => {
      service_principal          = sp.resource_name
      workload_identity_provider = hcp_iam_workload_identity_provider.github_wip[k].resource_name
    }
  }
}