variable "hcp_client_id" {
    description = "Client ID for HCP authentication (Requires Admin role for HCP project)"
    type        = string
    sensitive   = true
}

variable "hcp_client_secret" {
    description = "Client secret for HCP authentication (Requires Admin role for HCP project)"
    type        = string
    sensitive   = true
}

variable "hcp_project_id" {
    description = "HCP project ID"
    type        = string
    sensitive   = true
}

variable "workload_identity_providers_config" {
    description = "The OIDC providers configuration to create various workload identity providers for different Github repositories"
    type        = map(object({
        name                      = string
        actor_claim               = string
        repository_claim          = string
        ref_claims_regex          = string
        hcp_role                  = string
        workflow_ref_claims_regex = string
    }))
    default     = {
        packer-aws-azure-gcp = {
            name                      = "packer-aws-azure-gcp-github"
            actor_claim               = "Timotej979"
            repository_claim          = "Timotej979/Homelab-infrastructure-talos"
            ref_claims_regex           = "refs/heads/(main|stage|dev)"
            hcp_role                  = "roles/contributor"
            workflow_ref_claims_regex = "build_(aws|azure|gcp).yml"
        }
        packer-alicloud-tencent = {
            name                      = "packer-alicloud-tencent-github"
            actor_claim               = "Timotej979"
            repository_claim          = "Timotej979/Homelab-infrastructure-talos"
            ref_claims_regex           = "refs/heads/(main|stage|dev)"
            hcp_role                  = "roles/contributor"
            workflow_ref_claims_regex = "build_(alicloud|tencent).yml"
        }
        # terragrunt = {
        #     name             = "terragrunt-github"
        #     actor_claim      = "Timotej979"
        #     repository_claim = "Timotej979/Homelab-infrastructure-terragrunt"
        #     ref_claim        = "refs/heads/main"
        #     workflow_ref_claims = ""
        # }
    }
}