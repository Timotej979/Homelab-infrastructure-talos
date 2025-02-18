packer {
    required_plugins {
        digitalocean = {
            source  = "github.com/digitalocean/digitalocean"
            version = ">= 1.4.1"
        }
        external = {
            source  = "github.com/joomcode/external"
            version = ">= 0.0.2"
        }
    }
}

#############################################
variable "do_region" {
    description = "Digital Ocean Region"
    type        = string
    default     = "fra1"
}

variable "do_droplet_size" {
    description = "Droplet size"
    type        = string
    default     = "s-4vcpu-8gb"
}

#############################################
data "external" "talos_info" {
  program = ["bash", "${path.root}/../scripts/talos-info.sh"]
}

#############################################
locals {
    talos_version = data.external.talos_info.result.talos_version
    talos_arch = data.external.talos_info.result.talos_arch
    img_path = "${path.root}/../scripts/talos-img.raw.gz"
}

#############################################
source "digitalocean" "talos" {
    # The DO Cloud credentials
    api_token = var.do_token
    region    = var.do_region

    # The DO server configuration
    image     = "debian-11-x64"
    size      = var.do_droplet_size
    ssh_username = "root"

    snapshot_name = "talos-${local.talos_version}-${local.talos_arch}"

    snapshot_tags = {
        platform  = "digitalocean"
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

    sources = ["source.digitalocean.talos"]

    provisioner "file" {
        source      = local.img_path
        destination = "/tmp/talos.raw.gz"
    }

    provisioner "shell" {
        inline = [
        "gunzip -c /tmp/talos.raw.gz > /dev/sda"
        ]
    }

    post-processor "shell-local" {
        inline = [
            "trivy image $(packer manifest inspect | jq -r '.builds[0].artifact_id') -f json -o trivy-report.json"
        ]
    }
}