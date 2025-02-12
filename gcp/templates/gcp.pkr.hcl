packer {
    required_plugins {
        googlecompute = {
            source  = "github.com/hashicorp/googlecompute"
            version = ">= 1.1.6"
        }
        external = {
            source  = "github.com/joomcode/external"
            version = ">= 0.0.2"
        }
    }
}

#############################################
variable "gcp_project_id" {
    description = "GCP Project ID"
    type        = string
    sensitive   = true
}

variable "gcp_access_token" {
    description = "GCP Access Token"
    type        = string
    sensitive   = true
}

variable "gcp_zone" {
    description = "GCP Zone"
    type        = string
    default     = "europe-west1-b"
}

variable "gcp_instance_type" {
    description = "Instance type"
    type        = string
    default     = "t2a-standard-4"
}

#############################################
data "external" "talos_info" {
    program = ["bash", "${path.root}/../scripts/talos-info.sh"]
}

#############################################
locals {
    talos_version = data.external.talos_info.result.talos_version
    talos_arch = data.external.talos_info.result.talos_arch
    img_path = "${path.root}/../scripts/talos-img.raw.tar.xz"
    gcp_image_name = local.talos_arch == "amd64" ? "ubuntu-2404-lts-amd64" : "ubuntu-2404-lts-arm64"
}

#############################################
source "googlecompute" "talos" {
    # The GCP credentials
    project_id    = var.gcp_project_id
    access_token  = var.gcp_access_token
    zone          = var.gcp_zone

    # The GCP server configuration
    source_image  = data.googlecompute_image.ubuntu.self_link
    machine_type  = var.gcp_instance_type
    ssh_username  = "ubuntu"

    image_name    = "talos-system-disk-${local.talos_arch}-${local.talos_version}"
    image_family  = "talos-os"

    image_labels  = {
        platform  = "gcp"
        os        = "talos"
        version   = local.talos_version
        arch      = local.talos_arch
        timestamp = timestamp()
    }
}

#############################################
build {
    hcp_packer_registry {
        description  = "Homelab-infrastructure TalosOS images registry"
        bucket_name  = "homelab-infrastructure-talos"
        bucket_labels = {
            "packer_version" = packer.version
        }
    }

    sources = ["source.googlecompute.talos"]

    provisioner "file" {
        source      = local.img_path
        destination = "/tmp/talos.raw.tar.xz"
    }

    provisioner "shell" {
        inline = [
            "tar -xJf /tmp/talos.raw.tar.xz -O | dd of=/dev/sda bs=1M && sync"
        ]
    }

    post-processor "shell-local" {
        inline = [
            "trivy image $(packer manifest inspect | jq -r '.builds[0].artifact_id') -f json -o trivy-report.json"
        ]
    }
}
