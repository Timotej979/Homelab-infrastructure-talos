variable "aws_profile" {
    description = "AWS CLI profile"
    type        = string
    default     = "terraform"
}

variable "aws_region" {
    description = "AWS region"
    type        = string
    default     = "eu-central-1"
}

variable "workload_identity_providers_config" {
    description = "OIDC GitHub configurations"
    type = map(object({
        name                       = string
        actor_claim                = string
        repository_claim           = string
        ref_claim                  = string
        allowed_ec2_instance_types = list(string)
        workflow_ref_claims        = list(string)
    }))
    default = {
        packer-prod-gh = {
            name                       = "packer-prod-gh"
            actor_claim                = "Timotej979"
            repository_claim           = "Timotej979/Homelab-infrastructure-talos"
            ref_claim                  = "refs/heads/main"
            allowed_ec2_instance_types = ["t4g.medium", "t3a.medium"]
            workflow_ref_claims        = [
                "Timotej979/Homelab-infrastructure-talos/.github/workflows/build_aws.yml@refs/heads/main"
            ]
        }
        packer-stage-gh = {
            name                       = "packer-stage-gh"
            actor_claim                = "Timotej979"
            repository_claim           = "Timotej979/Homelab-infrastructure-talos"
            ref_claim                  = "refs/heads/stage"
            allowed_ec2_instance_types = ["t4g.medium", "t3a.medium"]
            workflow_ref_claims        = [
                "Timotej979/Homelab-infrastructure-talos/.github/workflows/build_aws.yml@refs/heads/stage"
            ]
        }
        packer-dev-gh = {
            name                       = "packer-dev-gh"
            actor_claim                = "Timotej979"
            repository_claim           = "Timotej979/Homelab-infrastructure-talos"
            ref_claim                  = "refs/heads/dev"
            allowed_ec2_instance_types = ["t4g.medium", "t3a.medium"]
            workflow_ref_claims        = [
                "Timotej979/Homelab-infrastructure-talos/.github/workflows/build_aws.yml@refs/heads/dev"
            ]
        }
    }
}