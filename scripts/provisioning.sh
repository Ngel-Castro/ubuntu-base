#! /bin/bash/env bash
export username=$1
export password=$2

# Description : Creating a virtual machine template under Ubuntu Server 24.04 LTS from ISO file with Packer using VMware Workstation
# Author : Yoann LAMY <https://github.com/ynlamy/packer-ubuntuserver24_04>
# Licence : GPLv3

mkdir -p /home/${username}/.ssh
cat /tmp/your-public-key-file >> /home/${username}/.ssh/authorized_keys
chown -R ${username}:${username} /home/${username}/.ssh
chmod 600 /home/${username}/.ssh/authorized_keys
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
echo ${password} | sudo -S apt-get update
echo ${password} | sudo -SE DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
echo ${password} | sudo -SE DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt-get install -y git ansible qemu-guest-agent cloud-init
echo ${password} | sudo -S systemctl enable qemu-guest-agent
echo "Configuring cloud-init for Proxmox NoCloud datasource"
echo ${password} | sudo -S tee /etc/cloud/cloud.cfg.d/99-pve.cfg > /dev/null << 'EOF'
datasource_list: [NoCloud, ConfigDrive]
EOF
# Remove baked-in static netplan so cloud-init writes network config from Proxmox ipconfig0 on clone
echo ${password} | sudo -S rm -f /etc/netplan/00-installer-config.yaml
rm /tmp/your-public-key-file
echo "Cleaning the unique machine-id for cloned VMs"
sudo rm -f /etc/machine-id && sudo touch /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id
echo "Resetting cloud-init state for clean first-boot on clone"
echo ${password} | sudo -S cloud-init clean --logs
