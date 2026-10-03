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
network_vlan_tag = "3"

# The static network the VM-being-baked gets during this platform's bake.
# The .pkr.hcl defaults for these still match the values below (they were
# hardcoded in http/user-data.pkrtpl before being variablized), but they're
# pinned here explicitly so this platform's bake never depends on template
# defaults -- other environments set their own via -var / `dante init`.
baking_ip      = "192.168.0.133"
baking_prefix  = 24
baking_gateway = "192.168.0.1"
baking_dns     = ["8.8.8.8", "8.8.4.4"]

# The SSH public key installed in the admin user's authorized_keys. The
# .pkr.hcl default is the same file, but it's pinned here explicitly so this
# platform's bake never depends on that default -- other environments'
# `dante init` bakes pass the operator's own ed25519 key instead.
public_key_file = "administrator.pub"
