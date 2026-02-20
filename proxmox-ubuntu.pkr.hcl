packer {
  required_plugins {
    name = {
      version = "~> 1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "proxmox_url" {}
variable "proxmox_user" {}
variable "proxmox_token" {}
variable "proxmox_node" {}
variable "iso_file" {}
variable "ssh_username" {}
variable "ssh_password" {}
variable "storage" {}
variable "hashed_password" {}
variable "public_key_file" {
  default = "administrator.pub"
}
variable "provisioning_script" {
  default = "scripts/provisioning.sh"
}




source "proxmox-iso" "ubuntu" {
  insecure_skip_tls_verify  = true
  proxmox_url               = var.proxmox_url
  username                  = var.proxmox_user
  token                     = var.proxmox_token
  node                      = var.proxmox_node
  iso_file                  = var.iso_file
  vm_name                   = "ubuntu-base-baking"
  disks {
    disk_size         = "32G"
    storage_pool      = var.storage
    type              = "scsi"
  }
  memory         = 2048
  cores          = 2
  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }
  ssh_username         = var.ssh_username
  ssh_password         = var.ssh_password
  ssh_timeout          = "15m"
  boot_wait      = "10s"
  boot_command = [
    "c<wait>",
    "linux /casper/vmlinuz autoinstall ds=nocloud<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]
  additional_iso_files {
    cd_content = {
      "user-data" = templatefile("http/user-data.pkrtpl", { hashed_password = var.hashed_password })
      "meta-data" = ""
    }
    cd_label         = "cidata"
    iso_storage_pool = var.storage
    unmount          = true
  }
  template_description = "Ubuntu 22.04, generated on ${timestamp()}"
  template_name        = "ubuntu-server-base"
  unmount_iso          = true
  tags                 = "packer;ubuntu;alpha"
}

build {
  sources = ["source.proxmox-iso.ubuntu"]

  provisioner "file" {
    source      = var.public_key_file
    destination = "/tmp/your-public-key-file"
  }

  provisioner "file" {
    source      = var.provisioning_script
    destination = "provisioning.sh"
  }

  provisioner "shell" {
    inline = [
      "chmod +x provisioning.sh",
      "bash provisioning.sh ${var.ssh_username} ${var.ssh_password}"
    ]
  }

}
