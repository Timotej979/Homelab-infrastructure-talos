terraform {
    required_version = ">= 1.12.0"

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = ">= 5.0"
        }
        external = {
            source  = "hashicorp/external"
            version = ">= 2.3.0"
        }
    }
}

provider "aws" {
    profile = var.aws_profile
    region  = var.aws_region
}

data "aws_caller_identity" "current" {}