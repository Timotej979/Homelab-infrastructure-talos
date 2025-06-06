output "workload_identity_pool_id" {
    description = "The Workload Identity Pool ID"
    value       = google_iam_workload_identity_pool.github_actions.workload_identity_pool_id
}

output "workload_identity_pool_provider_ids" {
    description = "Map of Workload Identity Provider IDs"
    value = {
        for k, provider in google_iam_workload_identity_pool_provider.github_actions_provider : 
            k => provider.workload_identity_pool_provider_id
    }
}