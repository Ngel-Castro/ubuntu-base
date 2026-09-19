proxmox_url   = "https://192.168.0.131:8006/api2/json"
proxmox_node   = "cloud"
iso_file       = "Kingstone_Backups:iso/ubuntu-24.04-live-server-amd64.iso"
ssh_username   = "administrator"
storage        = "Kingstone_Backups"

# my-ppm #231: network_adapters used to be hardcoded in the .pkr.hcl
# sources themselves (bridge=vmbr0, model=virtio, vlan_tag=3). They're now
# variables defaulting to no VLAN (bridge-only) -- these three lines
# reproduce this environment's actual network exactly as it was before.
network_bridge   = "vmbr0"
network_model    = "virtio"
network_vlan_tag = null
