# Base images dir
```
packer validate -var-file=base-values/common.pkvars.hcl -var "proxmox_user=${PROXMOX_TOKEN_ID}" -var "proxmox_token=${PROXMOX_TOKEN_SECRET}" -var "ssh_password=${CLUSTER_PASSWORD}"   proxmox-ubuntu.pkr.hcl
```