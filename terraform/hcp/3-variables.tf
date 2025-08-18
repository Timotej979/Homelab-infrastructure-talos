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
        name                = string
        actor_claim         = string
        repository_claim    = string
        ref_claim           = string
        hcp_role            = string
        workflow_ref_claims = list(string)
    }))
    default     = {
        packer-aws-azure-gcp = {
            name                = "packer-aws-azure-gcp-github"
            actor_claim         = "Timotej979"
            repository_claim    = "Timotej979/Homelab-infrastructure-talos"
            ref_claim           = "refs/heads/main"
            hcp_role            = "roles/contributor"
            workflow_ref_claims = [
                "Timotej979/Homelab-infrastructure-talos/.github/workflows/build-aws.yml@refs/heads/main",
                "Timotej979/Homelab-infrastructure-talos/.github/workflows/build-azure.yml@refs/heads/main",
                "Timotej979/Homelab-infrastructure-talos/.github/workflows/build-gcp.yml@refs/heads/main",
            ]
        }
        packer-alicloud-tencent = {
            name                = "packer-alicloud-tencent-github"
            actor_claim         = "Timotej979"
            repository_claim    = "Timotej979/Homelab-infrastructure-talos"
            ref_claim           = "refs/heads/main"
            hcp_role            = "roles/contributor"
            workflow_ref_claims = [
                "Timotej979/Homelab-infrastructure-talos/.github/workflows/build-alicloud.yml@refs/heads/main",
                "Timotej979/Homelab-infrastructure-talos/.github/workflows/build-tencent.yml@refs/heads/main"
            ]
        }
        # terragrunt = {
        #     name             = "terragrunt-github"
        #     actor_claim      = "Timotej979"
        #     repository_claim = "Timotej979/Homelab-infrastructure-terragrunt"
        #     ref_claim        = "refs/heads/main"
        #     workflow_ref_claims = []
        # }
    }
}