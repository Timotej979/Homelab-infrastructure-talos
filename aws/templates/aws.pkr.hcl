packer {
    required_plugins {
        aws = {
            source  = "github.com/hashicorp/amazon"
            version = ">= 1.2.8"
        }
        external = {
            source  = "github.com/joomcode/external"
            version = ">= 0.0.2"
        }
    }
}

#############################################
variable "aws_region" {
    description = "AWS Region"
    type        = string
    default     = "eu-central-1"
}

variable "aws_instance_type" {
    description = "Instance type"
    type        = string
    default     = "t4g.medium"
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
data "amazon-ami" "ubuntu" {
    filters = {
        name = "ubuntu/images/*ubuntu-jammy-22.04-${local.talos_arch}-server-*"
        virtualization-type = "hvm"
        root-device-type = "ebs"
    }
    most_recent = true
    owners      = ["099720109477"]
    region      = var.aws_region
}

#############################################
source "amazon-ebs" "talos" {
    # The AWS Cloud credentials
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
    region     = var.aws_region

    # The AWS Cloud server configuration
    source_ami = data.amazon-ami.ubuntu.id
    instance_type = var.aws_instance_type
    ssh_username = "ubuntu"
     
    ami_name = "talos-system-disk-${local.talos_arch}-${local.talos_version}"
    ami_description = "Talos OS ${local.talos_version} for ${local.talos_arch}"
    ami_users = ["all"]
    snapshot_users = ["all"]
    
    tags = {
        platform  = "aws"
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

    sources = ["source.amazon-ebs.talos"]

    provisioner "file" {
        source      = local.img_path
        destination = "/tmp/talos.raw.xz"
    }

    provisioner "shell" {
        inline = [
            "xz -d -c /tmp/talos.raw.xz | dd of=/dev/nvme0n1 bs=1M && sync"
        ]
    }

    post-processor "shell-local" {
        inline = [
            "trivy image $(packer manifest inspect | jq -r '.builds[0].artifact_id') -f json -o trivy-report.json"
        ]
    }
}