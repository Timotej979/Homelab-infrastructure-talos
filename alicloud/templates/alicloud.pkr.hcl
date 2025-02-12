packer {
    required_plugins {
        alicloud = {
            source  = "github.com/hashicorp/alicloud"
            version = ">= 1.1.2"
        }
        external = {
            source  = "github.com/joomcode/external"
            version = ">= 0.0.2"
        }
    }
}

#############################################
variable "alicloud_access_key" {
    description = "Alicloud Access Key"
    type        = string
    sensitive   = true
}

variable "alicloud_secret_key" {
    description = "Alicloud Secret Key"
    type        = string
    sensitive   = true
}

variable "alicloud_region" {
    description = "Alicloud Region"
    type        = string
    default     = "eu-central-1"
}

variable "alicloud_instance_type" {
    description = "Instance type"
    type        = string
    default     = "ecs.g8y.xlarge"
}

#############################################
data "external" "talos_info" {
  program = ["bash", "${path.root}/../scripts/talos-info.sh"]
}

#############################################
locals {
    talos_version = data.external.talos_info.result.talos_version
    talos_arch = data.external.talos_info.result.talos_arch
    img_path = "${path.root}/../scripts/talos-img.vhd"
    alicloud_image_name = local.talos_arch == "arm64" ? "aliyun_3_arm64_20G_nocloud_alibase_20240819.vhd" : "aliyun_3_x64_20G_nocloud_alibase_20240819.vhd"
}

#############################################
source "alicloud-ecs" "talos" {
    # The AliCloud credentials
    access_key = var.alicloud_access_key
    secret_key = var.alicloud_secret_key
    region     = var.alicloud_region

    # The AliCloud server configuration
    source_image = local.alicloud_image_name
    instance_type = var.alicloud_instance_type
    ssh_username = "root"

    image_name = "talos-system-disk-${local.talos_arch}-${local.talos_version}"
    image_description = "Talos OS ${local.talos_version} for ${local.talos_arch}"

    associate_public_ip_address = true
    io_optimized = true
    internet_charge_type = "PayByTraffic"
    skip_image_validation = true

    tags = {
        platform  = "alicloud"
        os        = "talos"
        version   = local.talos_version
        arch      = local.talos_arch
        timestamp = timestamp()
    }
}

#############################################
build {
    hcp_packer_registry {
        description = "Homelab-infrastructure TalosOS images registry"
        bucket_name = "homelab-infrastructure-talos"
        bucket_labels = {
            "packer_version" = packer.version
        }
    }

    sources = ["source.alicloud-ecs.talos"]

    provisioner "file" {
        source      = local.img_path
        destination = "/tmp/talos.vhd"
    }

    provisioner "shell" {
        inline = [
            "dd if=/tmp/talos.vhd of=/dev/vda bs=1M && sync"
        ]
    }

    post-processor "shell-local" {
        inline = [
            "trivy image $(packer manifest inspect | jq -r '.builds[0].artifact_id') -f json -o trivy-report.json"
        ]
    }
}
