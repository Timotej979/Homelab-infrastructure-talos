output "workload_identity_pool_id" {
    value = google_iam_workload_identity_pool.github_actions.workload_identity_pool_id
}

output "workload_identity_pool_provider_id" {
    value = google_iam_workload_identity_pool_provider.github_actions_provider[*].workload_identity_pool_provider_id
}