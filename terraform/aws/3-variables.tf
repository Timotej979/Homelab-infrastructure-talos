variable "aws_profile" {
    description = "AWS CLI profile"
    type        = string
}

variable "aws_region" {
    description = "AWS region"
    type        = string
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
            name                = "packer-gh-actions"
            actor_claim         = "Timotej979"
            repository_claim    = "Timotej979/Homelab-infrastructure-talos"
            ref_claim           = "refs/heads/main"
            workflow_ref_claims = [
                "Timotej979/Homelab-infrastructure-talos/.github/workflows/build-aws.yml@refs/heads/main"
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