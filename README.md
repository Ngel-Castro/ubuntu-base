# Ubuntu Base Images for Proxmox

This repository automates the creation of Ubuntu server base images (templates) for Proxmox virtualization platform using HashiCorp Packer. It provides infrastructure-as-code configurations to build two types of Ubuntu 24.04 LTS templates with automated provisioning.

## Overview

The repository uses Packer to create VM templates on Proxmox that can be used as base images for deploying new virtual machines. It supports two template configurations:

1. **Ubuntu Server Base** (`proxmox-ubuntu.pkr.hcl`) - A minimal Ubuntu server template with basic provisioning
2. **Ubuntu Web Server** (`proxmox-ubuntu-web.pkr.hcl`) - An Ubuntu server template with Apache2, PHP, and web development tools

## Key Components

### Packer Templates

- **`proxmox-ubuntu.pkr.hcl`**: Creates a basic Ubuntu server template with:
  - Ubuntu 24.04 LTS
  - 32GB disk, 2GB RAM, 2 CPU cores
  - SSH key authentication
  - Git and Ansible pre-installed
  - QEMU guest agent

- **`proxmox-ubuntu-web.pkr.hcl`**: Creates a web server template with everything in the base template plus:
  - Apache2 web server
  - PHP 8.x with common extensions (MySQL, GD, cURL, etc.)
  - Composer (PHP dependency manager)
  - Pre-configured Apache virtual host
  - Additional Ansible provisioning

### Provisioning

#### Shell Provisioning (`scripts/provisioning.sh`)
- Configures SSH key authentication
- Updates system packages
- Installs Git and Ansible
- Cleans machine-id for proper DHCP behavior in cloned VMs

#### Ansible Provisioning (`ansible/`)
- **Common role**: Configures passwordless sudo and updates apt cache
- **Apache role**: Installs and configures Apache2 and PHP stack

#### Cloud-Init Configuration (`http/user-data`)
- Automates Ubuntu installation with:
  - Default username: `administrator`
  - Hostname: `ubuntu-server`
  - Timezone: America/New_York
  - Network: DHCP on ens18
  - LVM storage layout
  - SSH server enabled

### CI/CD Integration

The repository includes Jenkins pipeline configurations for automated template building:

- **`ubuntubase.jenkinsfile`**: Builds the base Ubuntu template
- **`ubuntuwebserver.jenkinsfile`**: Builds the web server template

Both pipelines:
- Run bi-weekly (every other Monday)
- Validate Packer configurations
- Build and upload templates to Proxmox
- Use Jenkins credentials for Proxmox authentication

## Prerequisites

- **Proxmox VE** server (tested with Proxmox)
- **Packer** 1.8+
- **Ansible** 10.1.0+ (for web server template)
- **Python** 3.12+ (if using Poetry for dependency management)
- Ubuntu 24.04 LTS ISO uploaded to Proxmox storage
- Proxmox API token with appropriate permissions

### Jenkins Agent Requirements

The Jenkins agent nodes that run the pipelines must have the following tools available on `PATH` at runtime:

- **`packer`** — for building templates
- **`openssl`** — used to generate the SHA-512 hashed password at build time (`openssl passwd -6`). Without this, the pipeline will fail at the validate and build stages. Most Linux-based agents have it pre-installed; verify with `which openssl`. On Debian/Ubuntu agents it can be installed with `apt-get install -y openssl`.

## Configuration

### Variables File (`base-values/common.pkvars.hcl`)

Create or update the common variables file with your Proxmox details:

```hcl
proxmox_url   = "https://your-proxmox-server:8006/api2/json"
proxmox_node  = "your-node-name"
iso_file      = "storage:iso/ubuntu-24.04-live-server-amd64.iso"
ssh_username  = "administrator"
storage       = "your-storage-name"
```

### SSH Key

Place your public SSH key in `administrator.pub` at the repository root. This key will be added to the administrator user's authorized_keys.

## Usage

### Validating Configuration

```bash
packer validate \
  -var-file=base-values/common.pkvars.hcl \
  -var "proxmox_user=${PROXMOX_TOKEN_ID}" \
  -var "proxmox_token=${PROXMOX_TOKEN_SECRET}" \
  -var "ssh_password=${ADMIN_PASSWORD}" \
  -var "hashed_password=${HASHED_PASSWORD}" \
  proxmox-ubuntu.pkr.hcl
```

### Building the Base Template

```bash
packer init proxmox-ubuntu.pkr.hcl

packer build \
  -var-file=base-values/common.pkvars.hcl \
  -var "proxmox_user=${PROXMOX_TOKEN_ID}" \
  -var "proxmox_token=${PROXMOX_TOKEN_SECRET}" \
  -var "ssh_password=${ADMIN_PASSWORD}" \
  -var "hashed_password=${HASHED_PASSWORD}" \
  proxmox-ubuntu.pkr.hcl
```

### Building the Web Server Template

```bash
packer init proxmox-ubuntu-web.pkr.hcl

packer build \
  -var-file=base-values/common.pkvars.hcl \
  -var "proxmox_user=${PROXMOX_TOKEN_ID}" \
  -var "proxmox_token=${PROXMOX_TOKEN_SECRET}" \
  -var "ssh_password=${ADMIN_PASSWORD}" \
  -var "hashed_password=${HASHED_PASSWORD}" \
  proxmox-ubuntu-web.pkr.hcl
```

### Environment Variables

Set the following environment variables before running any Packer command:

```bash
export PROXMOX_TOKEN_ID="your-token-id"
export PROXMOX_TOKEN_SECRET="your-token-secret"
export ADMIN_PASSWORD="your-password"
export HASHED_PASSWORD=$(openssl passwd -6 "$ADMIN_PASSWORD")
```

- `PROXMOX_TOKEN_ID`: Your Proxmox API token ID
- `PROXMOX_TOKEN_SECRET`: Your Proxmox API token secret
- `ADMIN_PASSWORD`: The administrator user password (plaintext, used by Packer SSH provisioners)
- `HASHED_PASSWORD`: SHA-512 crypt hash of the password, generated via `openssl passwd -6`. This is injected into the cloud-init `user-data` at build time so no plaintext or static hash is stored in source control.

## Templates Created

After successful builds, you'll have the following templates in Proxmox:

- **ubuntu-server-base**: Basic Ubuntu server ready for customization
- **ubuntu-web-server-base**: Pre-configured web server with Apache and PHP

Both templates are tagged with `packer` and `ubuntu`. The web server template is additionally tagged with `web` and `alpha` (indicating it's in testing/development phase).

## Development

### Dependencies

Install dependencies using Poetry:

```bash
poetry install
```

This will install Ansible and other development dependencies.

## License

MIT License - See [LICENSE](LICENSE) file for details.

## Author

Angel Castro <castrobasurto.angel@gmail.com>

## Acknowledgments

Provisioning script adapted from [Yoann LAMY's packer-ubuntuserver24_04](https://github.com/ynlamy/packer-ubuntuserver24_04) (GPLv3 License)