terraform {
    required_version = ">= 1.12.0"

    required_providers {
        tencentcloud = {
            source  = "tencentcloudstack/tencentcloud"
            version = ">= 1.81.198"
        }
        external = {
            source  = "hashicorp/external"
            version = ">= 2.3.0"
        }
    }
}

provider "tencentcloud" {
    secret_id  = var.tencent_secret_id
    secret_key = var.tencent_secret_key
    region     = var.tencent_region
}