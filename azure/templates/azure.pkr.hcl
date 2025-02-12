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
variable "azure_client_id" {
    description = "Azure Client ID"
    type        = string
    sensitive   = true
}

variable "azure_client_secret" {
    description = "Azure Client Secret"
    type        = string
    sensitive   = true
}

variable "azure_subscription_id" {
    description = "Azure Subscription ID"
    type        = string
    sensitive   = true
}

variable "azure_tenant_id" {
    description = "Azure Tenant ID"
    type        = string
    sensitive   = true
}

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
    img_path = "${path.root}/../scripts/talos-img.raw.xz"
}

#############################################
source "azure-arm" "talos" {
    # The Azure Cloud credentials
    client_id       = var.azure_client_id
    client_secret   = var.azure_client_secret
    subscription_id = var.azure_subscription_id
    tenant_id       = var.azure_tenant_id

    source_image_reference = data.azure_image.ubuntu.id
    vm_size               = var.azure_vm_size
    ssh_username          = "ubuntu"

    image_name           = "talos-system-disk-${local.talos_arch}-${local.talos_version}"
    image_description    = "Talos OS ${local.talos_version} for ${local.talos_arch}"
    image_publisher      = "Talos"
    image_offer          = "Talos OS"
    image_sku            = "1.0"
  
    tags = {
        platform  = "azure"
        os        = "talos"
        version   = local.talos_version
        arch      = local.talos_arch
        timestamp = timestamp()
  }
}

#############################################
build {
    sources = ["source.azure-arm.talos"]

    provisioner "file" {
        source      = local.img_path
        destination = "/tmp/talos.raw.xz"
    }

    provisioner "shell" {
        inline = [
        "xz -d -c /tmp/talos.raw.xz | dd of=/dev/sda bs=1M && sync"
        ]
    }

    post-processor "shell-local" {
        inline = [
            "trivy image $(packer manifest inspect | jq -r '.builds[0].artifact_id') -f json -o trivy-report.json"
        ]
    }
}