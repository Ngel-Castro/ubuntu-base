#! /bin/bash/env bash
export username=$1
export password=$2
export harbor_robot_user=$3
export harbor_robot_password=$4

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
echo "Installing Vacks CA root certificate for *.dev.home trust (harbor.dev.home, etc.)"
echo ${password} | sudo -S cp /tmp/vacks-root-ca.crt /usr/local/share/ca-certificates/vacks-ca.crt
echo ${password} | sudo -S update-ca-certificates
echo ${password} | sudo -S mkdir -p /etc/docker/certs.d/harbor.dev.home
echo ${password} | sudo -S cp /tmp/vacks-root-ca.crt /etc/docker/certs.d/harbor.dev.home/ca.crt
rm /tmp/vacks-root-ca.crt

# Bake Harbor registry pull credentials so this node (and any clone) can pull
# private harbor.dev.home/dante/* images from first boot, with no manual
# `docker login` step (my-ppm #193). Uses a scoped, pull-only Harbor robot
# account rather than a personal login. Written for root (kubelet/dockershim
# pulls images as root) and for ${username} (manual docker use on the node).
if [ -n "${harbor_robot_user}" ]; then
  echo "Baking Harbor pull credentials for harbor.dev.home (robot account: ${harbor_robot_user})"
  harbor_auth=$(printf '%s:%s' "${harbor_robot_user}" "${harbor_robot_password}" | base64 -w0)
  harbor_docker_config=$(printf '{"auths":{"harbor.dev.home":{"auth":"%s"}}}' "${harbor_auth}")

  echo ${password} | sudo -S mkdir -p /root/.docker
  echo "${harbor_docker_config}" | sudo -S tee /root/.docker/config.json > /dev/null
  echo ${password} | sudo -S chmod 600 /root/.docker/config.json

  mkdir -p /home/${username}/.docker
  echo "${harbor_docker_config}" > /home/${username}/.docker/config.json
  chmod 600 /home/${username}/.docker/config.json
  chown -R ${username}:${username} /home/${username}/.docker
else
  echo "No Harbor robot credentials provided — skipping Harbor pull credential baking"
fi
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
