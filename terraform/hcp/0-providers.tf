terraform {
    required_version = ">= 1.12.0"

    required_providers {
        hcp = {
            source  = "hashicorp/hcp"
            version = ">= 0.106.0"
        }
    }
}

provider "hcp" {
    client_id     = var.hcp_client_id
    client_secret = var.hcp_client_secret
    project_id    = var.hcp_project_id
}