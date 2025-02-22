variable "hcp_client_id" {
    description = "The client ID for HCP authentication (Requires Admin role for HCP project)"
    type        = string
    sensitive   = true
}

variable "hcp_client_secret" {
    description = "The client secret for HCP authentication (Requires Admin role for HCP project)"
    type        = string
    sensitive   = true
}

variable "hcp_project_id" {
    description = "The HCP project ID"
    type        = string
    sensitive   = true
}

variable "workload_identity_providers_config" {
    description = "The OIDC providers configuration to create various workload identity providers for different Github repositories"
    type        = map(object({
        name             = string
        repository_claim = string
        ref_claim        = string
    }))
    default     = {
        packer = {
            name             = "packer-gh-actions"
            repository_claim = "Timotej979/Homelab-infrastructure-talos"
            ref_claim        = "refs/heads/main"
        }
        terragrunt = {
            name             = "terragrunt-gh-actions"
            repository_claim = "Timotej979/Homelab-infrastructure-terragrunt"
            ref_claim        = "refs/heads/main"
        }
    }
}