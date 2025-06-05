packer {
    required_plugins {
        proxmox = {
            source  = "github.com/hashicorp/proxmox"
            version = ">= 1.2.2"
        }
        external = {
            source  = "github.com/joomcode/external"
            version = ">= 0.0.2"
        }
    }
}
