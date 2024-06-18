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
variable "public_key_file" {
  default = "administrator.pub"
}


source "proxmox-iso" "ubuntu" {
  insecure_skip_tls_verify  = true
  proxmox_url               = var.proxmox_url
  username                  = var.proxmox_user
  token                     = var.proxmox_token
  node                      = var.proxmox_node
  iso_file                  = var.iso_file
  vm_name                   = "ubuntu-base-image-alpha"
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
  boot_command = ["e<wait><down><down><down><end> autoinstall 'ds=nocloud;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/'<F10>"]
  template_description = "Ubuntu 22.04, generated on ${timestamp()}"
  template_name        = "ubuntu-server-base"
  http_directory       = "http"
  unmount_iso          = true
  tags                 = "packer;ubuntu"
}

build {
  sources = ["source.proxmox-iso.ubuntu"]

  provisioner "file" {
    source      = var.public_key_file
    destination = "/tmp/your-public-key-file"
  }

  provisioner "shell" {
    inline = [
      "mkdir -p /home/${var.ssh_username}/.ssh",
      "cat /tmp/your-public-key-file >> /home/${var.ssh_username}/.ssh/authorized_keys",
      "chown -R ${var.ssh_username}:${var.ssh_username} /home/${var.ssh_username}/.ssh",
      "chmod 600 /home/${var.ssh_username}/.ssh/authorized_keys",
      "rm /tmp/your-public-key-file",
      "echo ${var.ssh_password} | sudo -S apt-get update ",
      "echo ${var.ssh_password} | sudo -S apt-get upgrade -y ",
      "echo ${var.ssh_password} | sudo -S apt-get install -y git",
    ]
  }

}
