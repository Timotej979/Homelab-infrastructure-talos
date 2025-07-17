variable "alicloud_profile" {
    description = "Alicloud CLI profile"
    type        = string
    default     = "terraform"
}

variable "alicloud_region" {
    description = "Alicloud region"
    type        = string
    default     = "eu-central-1"
}

variable "workload_identity_providers_config" {
    description = "OIDC GitHub configurations"
    type = map(object({
        name                = string
        actor_claim         = string
        repository_claim    = string
        ref_claim           = string
        workflow_ref_claims = list(string)
    }))
    default = {
        packer = {
            name                = "packer-github"
            actor_claim         = "Timotej979"
            repository_claim    = "Timotej979/Homelab-infrastructure-talos"
            ref_claim           = "refs/heads/main"
            workflow_ref_claims = [
                "Timotej979/Homelab-infrastructure-talos/.github/workflows/build-alicloud.yml@refs/heads/main"
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