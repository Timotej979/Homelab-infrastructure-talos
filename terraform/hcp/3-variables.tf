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
        workflow_ref_claims = list(string)
    }))
    default     = {
        packer = {
            name                = "packer-gh-actions"
            actor_claim         = "Timotej979"
            repository_claim    = "Timotej979/Homelab-infrastructure-talos"
            ref_claim           = "refs/heads/main"
            workflow_ref_claims = [
                for workflow_name in [
                    "build-all.yml",
                    "build-alicloud.yml",
                    "build-aws.yml",
                    "build-azure.yml",
                    "build-digital-ocean.yml",
                    "build-gcp.yml",
                    "build-hetzner.yml",
                    "build-huawei.yml",
                    "build-ibm.yml",
                    "build-linode.yml",
                    "build-oci.yml",
                    "build-ovh.yml",
                    "build-tencent.yml",
                    "build-vultr.yml"
                ] : "Timotej979/Homelab-infrastructure-talos/.github/workflows/${workflow_name}@refs/heads/main"
            ]
        }
        # terragrunt = {
        #     name             = "terragrunt-gh-actions"
        #     actor_claim      = "Timotej979"
        #     repository_claim = "Timotej979/Homelab-infrastructure-terragrunt"
        #     ref_claim        = "refs/heads/main"
        #     workflow_ref_claims = []
        # }
    }
}