packer {
    required_plugins {
        hcloud = {
            source  = "github.com/hetznercloud/hcloud"
            version = "~> 1"
        }
    }
}

locals {
    talos_info = jsondecode(run_local("${path.root}/../scripts/talos-info.sh"))
    talos_version = talos_info.version
    talos_arch = talos_info.arch
    img_path = "${path.root}/../scripts/talos-img.raw.gz"
}

source "hcloud" "talos" {
  rescue       = "linux64"
  image        = "debian-11"
  location     = "nbg1"
  server_type  = "cx11"
  ssh_username = "root"

  snapshot_name   = "talos system disk - ${local.talos_arch} - ${local.talos_version}"
  snapshot_labels = {
    type    = "infra"
    os      = "talos"
    version = local.talos_version
    arch    = local.talos_arch
  }
}

build {
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
