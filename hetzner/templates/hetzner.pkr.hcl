packer {
    required_plugins {
        hcloud = {
            source  = "github.com/hetznercloud/hcloud"
            version = "~> 1"
        }
        external = {
            source  = "github.com/joomcode/external"
            version = "~> 0.0.2"
        }
    }
}

variable "hcloud_token" {
    description = "The Hetzner Cloud API token"
    type        = string
    sensitive   = true
}

variable "server_type" {
    description = "The Hetzner Cloud server type to use"
    type        = string
    default     = "cx22"
    sensitive   = true
}

variable "location" {
    description = "The Hetzner Cloud location to use"
    type        = string
    default     = "nbg1"
    sensitive   = true
    validation {
        condition     = can(regex("nbg1|fsn1|hel1", var.location))
        error_message = "The location must be one of nbg1, fsn1, or hel1."
    }
}

data "external" "talos_info" {
  program = ["bash", "${path.root}/../scripts/talos-info.sh"]
}

locals {
    talos_version = data.external.talos_info.result.talos_version
    talos_arch = data.external.talos_info.result.talos_arch
    img_path = "${path.root}/../scripts/talos-img.raw.gz"
}

source "hcloud" "talos" {
    token        = var.hcloud_token
    rescue       = "linux64"
    image        = "debian-11"
    location     = var.location
    server_type  = var.server_type
    ssh_username = "root"

    snapshot_name   = "talos-system-disk-${local.talos_arch}-${local.talos_version}"
    snapshot_labels = {
        platform  = "aws"
        os        = "talos"
        version   = local.talos_version
        arch      = local.talos_arch
        timestamp = timestamp()
    }
}

build {
    hcp_packer_registry {
        description = "Homelab-infrastructure TalosOS images registry"
        bucket_name = "homelab-infrastructure-talos"
        bucket_labels = {
            "packer_version" = packer.version
        }
    }

    sources = ["source.hcloud.talos"]

    provisioner "file" {
        source      = local.image_path
        destination = "/tmp/talos.raw.xz"
    }

    provisioner "shell" {
        inline = [
        "xz -d -c /tmp/talos.raw.xz | dd of=/dev/sda && sync"
        ]
    }
}
