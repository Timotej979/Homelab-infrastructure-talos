terraform {
    required_version = ">= 1.12.0"

    required_providers {
        alicloud = {
            source  = "aliyun/alicloud"
            version = ">= 1.250.0"
        }
        external = {
            source  = "hashicorp/external"
            version = ">= 2.3.0"
        }
    }
}

provider "alicloud" {
    profile = var.alicloud_profile
    region  = var.alicloud_region
}