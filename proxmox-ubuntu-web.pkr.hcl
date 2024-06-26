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
variable "administrator_public_key_file" {
  default = "administrator.pub"
}
variable "jenkins_public_key_file" {
  default = "jenkins.pub"
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
  vm_name                   = "ubuntu-web-server-baking"
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
  template_name        = "ubuntu-web-server-base"
  http_directory       = "http"
  unmount_iso          = true
  tags                 = "packer;ubuntu;alpha;web"
}

build {
  sources = ["source.proxmox-iso.ubuntu"]


  provisioner "file" {
    source      = var.administrator_public_key_file
    destination = "/tmp/administrator-key-file"
  }

  provisioner "file" {
    source      = var.jenkins_public_key_file
    destination = "/tmp/jenkins-key-file"
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

  provisioner "ansible" {
    playbook_file = "ansible/main.yml"
    extra_arguments = [
      "--extra-vars",
      "ansible_sudo_pass=${var.ssh_password}"
    ]
  }

}
