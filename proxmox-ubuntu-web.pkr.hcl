packer {
  required_plugins {
    proxmox = {
      version = "~> 1"
      source  = "github.com/hashicorp/proxmox"
    }
    ansible = {
      version = "~> 1"
      source  = "github.com/hashicorp/ansible"
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
variable "baking_ip" {
  default = "192.168.0.135"
}
variable "ansible_command" {
  default = "ansible-playbook"
}
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
  vm_name                   = "ubuntu-web-server-baking"
  boot_iso {
    type     = "ide"
    iso_file = var.iso_file
    unmount  = true
  }
  disks {
    disk_size         = "32G"
    storage_pool      = var.storage
    type              = "scsi"
  }
  memory         = 2048
  cores          = 2
  network_adapters {
    bridge   = "vmbr0"
    model    = "virtio"
    vlan_tag = "3"
  }
  ssh_username         = var.ssh_username
  ssh_password         = var.ssh_password
  ssh_host             = var.baking_ip
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
      "user-data" = templatefile("http/user-data.pkrtpl", { hashed_password = var.hashed_password, baking_ip = var.baking_ip })
      "meta-data" = ""
    }
    cd_label         = "cidata"
    iso_storage_pool = var.storage
    unmount          = true
  }
  template_description = "Ubuntu 22.04, generated on ${timestamp()}"
  template_name        = "ubuntu-web-server-base"
  tags                 = "packer;ubuntu;alpha;web"
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
    expect_disconnect = true
    inline = [
      "chmod +x provisioning.sh",
      "bash provisioning.sh ${var.ssh_username} ${var.ssh_password}"
    ]
  }

  provisioner "ansible" {
    playbook_file = "ansible/main.yml"
    command       = var.ansible_command
    pause_before  = "30s"
    max_retries   = 3
    extra_arguments = [
      "--extra-vars",
      "ansible_sudo_pass=${var.ssh_password}",
      "--scp-extra-args",
      "'-O'"
    ]
  }

}
