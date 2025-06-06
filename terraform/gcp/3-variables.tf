variable "gcp_credentials_file_path" {
    description = "The path to the GCP credentials file"
    type        = string
}

variable "gcp_project_id" {
    description = "The GCP project ID"
    type        = string
}

variable "gcp_region" {
    description = "The GCP region"
    type        = string
}

variable "workload_identity_providers_config" {
    description = "The OIDC providers configuration to create various workload identity providers for different GitHub repositories"
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
                "Timotej979/Homelab-infrastructure-talos/.github/workflows/build-gcp.yml@refs/heads/main"
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