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
variable "channel" {
    description = "Talos channel to use (aws-dev, aws-stage, aws-prod)"
    type        = string
    default     = "aws-dev"
}

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

variable "talos_version" {
    description = "Talos version to install"
    type        = string
    default     = "latest"
}

variable "talos_architecture" {
    description = "Talos architecture to install (amd64 or arm64)"
    type        = string
    default     = "arm64"
}

variable "talos_extensions" {
    description = "Talos extensions to install"
    type        = list(string)
    default     = []
}

#############################################
data "external" "talos_info" {
    program = ["bash", "${path.root}/../scripts/install-talos.sh"]

    query = {
        version    = var.talos_version
        arch       = var.talos_architecture
        extensions = jsonencode(var.talos_extensions)
    }
}

#############################################
locals {
    talos_version = data.external.talos_info.result.talos_version
    talos_arch    = data.external.talos_info.result.architecture
    img_path      = "${path.root}/talos-img.raw.xz"
}

#############################################
data "amazon-ami" "ubuntu" {
    filters = {
        name                = "ubuntu/images/*ubuntu-jammy-22.04-${local.talos_arch}-server-*"
        virtualization-type = "hvm"
        root-device-type    = "ebs"
    }
    most_recent = true
    owners      = ["099720109477"]
    region      = var.aws_region
}

#############################################
source "amazon-ebssurrogate" "talos" {
    region        = var.aws_region
    instance_type = var.aws_instance_type

    source_ami             = data.amazon-ami.ubuntu.id
    ssh_username           = "ubuntu"
    ami_virtualization_type = "hvm"

    ami_name        = "talos-${local.talos_arch}-${local.talos_version}-${formatdate("YYYYMMDDhhmmss", timestamp())}"
    ami_description = "Talos OS ${local.talos_version} for ${local.talos_arch}"

    launch_block_device_mappings {
        device_name           = "/dev/sdb"
        volume_size           = 20
        volume_type           = "gp3"
        delete_on_termination = true
    }

    ami_root_device {
        source_device_name    = "/dev/sdb"
        device_name           = "/dev/sdb"
        delete_on_termination = true
    }

    launch_block_device_mappings {
        device_name           = "/dev/sda1"
        volume_size           = 10
        volume_type           = "gp3"
        delete_on_termination = true
    }

    tags = {
        platform  = "aws"
        os        = "talos"
        channel   = var.channel
        version   = local.talos_version
        arch      = local.talos_arch
        timestamp = timestamp()
    }
}

#############################################
hcp_packer_registry {
    bucket_name = "homelab-infrastructure-talos"
    description = "Talos AMIs for Cloud"
    build_labels = {
        "platform"  = "aws"
        "version"   = local.talos_version
        "arch"      = local.talos_arch
        "timestamp" = timestamp()
        "channel"   = var.channel
    }
}

#############################################
build {
    sources = ["source.amazon-ebssurrogate.talos"]

    provisioner "file" {
        source      = local.img_path
        destination = "/tmp/talos.raw.xz"
    }

    provisioner "shell" {
        inline = [
            <<-EOF
            set -eux

            export SEC_PATH=""
            for i in {1..10}; do
                SEC_DEV=$(lsblk -ndo NAME,MOUNTPOINT | awk '$2=="" {print $1}' | grep -v "^nvme0n1$" | head -n1)
                if [ -n "$SEC_DEV" ]; then
                    export SEC_PATH="/dev/$SEC_DEV"
                    break
                fi
                echo "Waiting for secondary device..."
                sleep 2
            done

            if [ -z $SEC_PATH ]; then
                echo "❌ Secondary device not found after waiting"
                exit 1
            fi

            echo "✅ Found secondary block device: $SEC_PATH"
            
            # Verify uploaded file exists and is not empty
            if [ ! -f /tmp/talos.raw.xz ]; then
                echo "❌ File /tmp/talos.raw.xz does not exist"
                exit 1
            fi
            
            FILE_SIZE=$(stat -c%s /tmp/talos.raw.xz)
            if [ "$FILE_SIZE" -eq 0 ]; then
                echo "❌ File /tmp/talos.raw.xz is empty (size: $FILE_SIZE)"
                exit 1
            fi
            echo "✅ File size check passed: $FILE_SIZE bytes"
            
            # Test xz file integrity before decompression
            echo "✅ Verifying xz file integrity..."
            if ! xz -t /tmp/talos.raw.xz; then
                echo "❌ xz file integrity check failed - file may be corrupted"
                exit 1
            fi
            echo "✅ xz file integrity check passed"
            
            echo "✅ Writing Talos raw image to $SEC_PATH..."
            # Use xz -dc instead of xzcat for better error handling
            if ! sudo xz -dc /tmp/talos.raw.xz | sudo dd of=$SEC_PATH bs=1M conv=fsync status=progress; then
                echo "❌ Failed to write image to $SEC_PATH"
                exit 1
            fi
            sync
            echo "✅ Image written successfully"
            EOF
        ]
    }
}