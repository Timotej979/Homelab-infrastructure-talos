terraform {
    required_providers {
        google = {
            source  = "hashicorp/google"
            version = ">= 6.21.0"
        }
    }
}

provider "google" {
    credentials = var.gcp_credentials_file_path 
    project     = var.gcp_project_id
    region      = var.gcp_region
}