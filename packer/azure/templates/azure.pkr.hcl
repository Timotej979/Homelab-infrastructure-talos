packer {
    required_plugins {
        azure = {
            source  = "github.com/hashicorp/azure"
            version = ">= 2"
        }
        external = {
            source  = "github.com/joomcode/external"
            version = ">= 0.0.2"
        }
    }
}

#############################################
variable "azure_region" {
    description = "Azure Region"
    type        = string
    default     = "FranceCentral"
}

variable "azure_vm_size" {
    description = "VM Size"
    type        = string
    default     = "Standard_B2ms"
}

#############################################
data "external" "talos_info" {
    program = ["bash", "${path.root}/../scripts/talos-info.sh"]
}

#############################################
locals {
    talos_version = data.external.talos_info.result.talos_version
    talos_arch = data.external.talos_info.result.talos_arch
    img_path = "${path.root}/../scripts/talos-img.vhd.xz"
    azure_image_sku = local.talos_arch == "amd64" ? "11" : "11-arm64"
}

#############################################
source "azure-arm" "talos" {
    # The Azure Cloud location
    location        = var.azure_region

    # # The Azure server configuration
    storage_account       = "talos-storage"
    resource_group_name   = "talos-rg"
    os_type               = "Linux"
    image_publisher       = "Debian"
    image_offer           = "debian-11"
    image_sku             = local.azure_image_sku
    vm_size               = var.azure_vm_size
    ssh_username          = "debian"

    managed_image_name    = "talos-system-disk-${local.talos_arch}-${local.talos_version}"
    managed_image_resource_group_name = "talos-rg"
  
    azure_tags = {
        platform  = "azure"
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

    sources = ["source.azure-arm.talos"]

    provisioner "file" {
        source      = local.img_path
        destination = "/tmp/talos.vhd.xz"
    }

    # Maybe add another shell-local provider to upload the image to the registry 
    # (Similar alternative approach can be used for other cloud platforms if direct overwrite is not possible, might even be better)

    provisioner "shell" {
        inline = [
        "xz -d -c /tmp/talos.vhd.xz | dd of=/dev/sda bs=1M && sync"
        ]
    }

    post-processor "shell-local" {
        inline = [
            "trivy image $(packer manifest inspect | jq -r '.builds[0].artifact_id') -f json -o trivy-report.json"
        ]
    }
}