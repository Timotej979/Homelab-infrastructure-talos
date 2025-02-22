terraform {
    required_providers {
        hcp = {
            source  = "hashicorp/hcp"
            version = "~> 0.103.0"
        }
    }
}

provider "hcp" {
    client_id     = var.hcp_client_id
    client_secret = var.hcp_client_secret
    project_id    = var.hcp_project_id
}