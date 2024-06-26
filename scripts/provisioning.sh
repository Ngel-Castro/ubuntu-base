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
echo ${password} | sudo -S apt-get update 
echo ${password} | sudo -S apt-get upgrade -y 
echo ${password} | sudo -S apt-get install -y git
rm /tmp/your-public-key-file
echo "Cleaning the unique machine-id for dhcp"
sudo rm -f sudo /etc/machine-id && sudo touch /etc/machine-id 
sudo rm -f /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id