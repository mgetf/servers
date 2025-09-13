# MGE.TF Infrastructure - Complete Documentation

## Table of Contents
- [Overview](#overview)
- [Architecture Explained](#architecture-explained)
- [What We've Built](#what-weve-built)
- [Prerequisites](#prerequisites)
- [Quick Start Guide](#quick-start-guide)
- [Provider Configuration](#provider-configuration)
  - [DigitalOcean Setup](#digitalocean-setup)
  - [Vultr Setup](#vultr-setup)
  - [AWS/EC2 Setup](#awsec2-setup)
  - [Linode Setup](#linode-setup)
  - [Self-Hosted Wings](#self-hosted-wings)
- [Migration from Existing Infrastructure](#migration-from-existing-infrastructure)
- [Advanced Configuration](#advanced-configuration)
- [Troubleshooting](#troubleshooting)

## Overview

This infrastructure provides a complete, production-ready deployment system for Team Fortress 2 MGE (My Gaming Edge) servers using modern DevOps practices. We've combined Pterodactyl Panel (a game server management system) with Terraform (infrastructure as code) to create a scalable, maintainable solution that can be deployed across multiple cloud providers or on-premises hardware.

### What is MGE?
MGE is a competitive Team Fortress 2 mod where players fight 1v1 (or 2v2) in small arenas to practice their combat skills. It's the primary training tool for competitive TF2 players.

### Why This Architecture?
Traditional game server hosting involves manual SSH management, complex configurations, and limited scalability. Our solution provides:
- **Web-based management** via Pterodactyl Panel
- **Infrastructure as Code** for reproducible deployments
- **Multi-region support** for global player coverage
- **Automatic updates** and maintenance
- **Cost optimization** through dynamic scaling
- **Modern monitoring** and observability

## Architecture Explained

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                            │
└─────────────────┬───────────────────────┬───────────────────┘
                  │                       │
                  ▼                       ▼
         ┌──────────────┐        ┌──────────────┐
         │   Players    │        │   Admins     │
         └──────┬───────┘        └──────┬───────┘
                │                        │
                ▼                        ▼
    ┌───────────────────────────────────────────────┐
    │          Pterodactyl Panel (Control Plane)    │
    │  ┌─────────────────────────────────────────┐  │
    │  │ - Web UI (React/PHP)                    │  │
    │  │ - REST API                              │  │
    │  │ - User Management                       │  │
    │  │ - Server Orchestration                  │  │
    │  │ - Resource Allocation                   │  │
    │  │ - Database (MySQL/MariaDB)              │  │
    │  └─────────────────────────────────────────┘  │
    │         Hosted on: DigitalOcean NYC           │
    └────────────────┬───────────────────────────────┘
                     │ HTTPS API + WebSocket
                     │ (Optional: WireGuard VPN)
    ┌────────────────┴───────────────────────────────┐
    │                                                 │
    ▼                                                 ▼
┌─────────────────────┐                   ┌─────────────────────┐
│   Wings Node West   │                   │   Wings Node East   │
│  ┌────────────────┐ │                   │  ┌────────────────┐ │
│  │ Wings Daemon   │ │                   │  │ Wings Daemon   │ │
│  │ - Docker Host  │ │                   │  │ - Docker Host  │ │
│  │ - SFTP Server  │ │                   │  │ - SFTP Server  │ │
│  │ - File Manager │ │                   │  │ - File Manager │ │
│  └────────────────┘ │                   │  └────────────────┘ │
│  ┌────────────────┐ │                   │  ┌────────────────┐ │
│  │ TF2 Container 1│ │                   │  │ TF2 Container 1│ │
│  │ - SRCDS        │ │                   │  │ - SRCDS        │ │
│  │ - SourceMod    │ │                   │  │ - SourceMod    │ │
│  │ - MGEMod       │ │                   │  │ - MGEMod       │ │
│  └────────────────┘ │                   │  └────────────────┘ │
│  ┌────────────────┐ │                   │  ┌────────────────┐ │
│  │ TF2 Container 2│ │                   │  │ TF2 Container 2│ │
│  └────────────────┘ │                   │  └────────────────┘ │
│   Vultr LAX (US-W)  │                   │   Vultr EWR (US-E)  │
└─────────────────────┘                   └─────────────────────┘
```

### Component Breakdown

#### 1. Pterodactyl Panel (Control Plane)
- **Purpose**: Central management interface for all game servers
- **Components**:
  - Web UI for administrators and users
  - REST API for automation
  - Database storing server configs, users, permissions
  - Queue workers for background tasks
  - Scheduler for automated tasks
- **Location**: Single instance, typically on DigitalOcean

#### 2. Wings Nodes (Data Plane)
- **Purpose**: Actual game server hosting
- **Components**:
  - Wings daemon (Go-based agent)
  - Docker runtime for containerization
  - SFTP server for file access
  - Local storage for game files
- **Location**: Multiple instances across regions

#### 3. Docker Containers
- **Purpose**: Isolated game server instances
- **Components**:
  - TF2 Dedicated Server (SRCDS)
  - Metamod:Source (plugin framework)
  - SourceMod (server administration)
  - MGEMod (Ampere's fork with 2v2 support)
  - Custom configurations and maps

## What We've Built

### Terraform Infrastructure (`/terraform`)

Our Terraform configuration creates and manages:

1. **Main Configuration** (`main.tf`)
   - SSH key generation for all nodes
   - Panel deployment module
   - Wings deployment module(s)
   - Custom egg creation
   - Optional DNS management
   - WireGuard VPN mesh network

2. **Panel Module** (`modules/panel/`)
   - DigitalOcean droplet provisioning
   - Ubuntu 22.04 with Docker
   - Nginx reverse proxy with SSL
   - MariaDB/MySQL database
   - Redis for caching
   - Automatic Pterodactyl installation
   - Let's Encrypt SSL certificates
   - UFW firewall configuration

3. **Wings Module** (`modules/wings/`)
   - Multi-provider support (Vultr, DO, AWS, custom)
   - Docker installation and configuration
   - Wings daemon setup
   - Automatic panel registration
   - Network optimization
   - Security hardening

4. **Egg Module** (`modules/egg/`)
   - Custom TF2 MGE server template
   - Automated installation script
   - SourceMod plugin compilation
   - Map downloads
   - Configuration templates

### Docker Container (`/docker`)

Custom-built container optimized for TF2 MGE:
- Base Ubuntu 22.04 with 32-bit libraries
- SteamCMD for server updates
- Pre-configured for Pterodactyl integration
- Entrypoint script for dynamic configuration

### Migration Tools

- `migrate_from_ansible.sh`: Extracts configurations from existing Ansible setups
- Preserves SourceMod plugins and customizations
- Converts YAML configs to Terraform variables

## Prerequisites

### Required Software
```bash
# macOS
brew install terraform awscli doctl
brew install --cask docker

# Linux (Ubuntu/Debian)
apt-get update
apt-get install -y terraform docker.io curl git make

# Windows (via Chocolatey)
choco install terraform docker-desktop git make
```

### Required Accounts & API Keys

1. **Cloud Provider Account(s)**:
   - DigitalOcean: https://cloud.digitalocean.com/account/api/tokens
   - Vultr: https://my.vultr.com/settings/#settingsapi
   - AWS: IAM user with EC2 permissions
   - Linode: https://cloud.linode.com/profile/tokens

2. **Domain Name** (recommended):
   - For panel access (e.g., panel.mge.tf)
   - For SSL certificates

3. **Optional Services**:
   - Cloudflare (DNS management)
   - GitHub (Docker registry)
   - PlanetScale/Neon (managed database)

## Quick Start Guide

### Step 1: Clone and Configure

```bash
# Clone the repository
git clone https://github.com/mgetf/servers.git
cd servers/terraform

# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit configuration
nano terraform.tfvars
```

### Step 2: Configure terraform.tfvars

```hcl
# REQUIRED: API Credentials
do_token      = "dop_v1_xxxxxxxxxxxxxxxxxx"  # DigitalOcean API token
vultr_api_key = "XXXXXXXXXXXXXXXXXX"         # Vultr API key

# REQUIRED: Panel Settings
panel_admin_email = "admin@yourdomain.com"   # Your email
panel_domain      = "panel.yourdomain.com"   # Panel subdomain

# Basic 2-region setup (West + East US)
wings_nodes = {
  west = {
    provider = "vultr"
    region   = "lax"        # Los Angeles
    size     = "vc2-2c-4gb" # 2 CPU, 4GB RAM
  }
  east = {
    provider = "vultr"
    region   = "ewr"        # New Jersey
    size     = "vc2-2c-4gb"
  }
}
```

### Step 3: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy infrastructure
terraform apply

# This will output:
# - Panel URL
# - Panel IP address
# - Wings node IPs
# - SSH key location
```

### Step 4: Create Admin User

```bash
# SSH into panel
ssh -i keys/pterodactyl_key.pem root@<PANEL_IP>

# Create admin user
cd /var/www/pterodactyl
php artisan p:user:create

# Follow prompts:
# - Email: your-email@domain.com
# - Username: admin
# - Name: Your Name
# - Password: (secure password)
# - Admin: yes
```

### Step 5: Access Panel

1. Navigate to https://panel.yourdomain.com
2. Login with admin credentials
3. Configure Wings nodes in Admin → Nodes
4. Create servers using TF2 MGE egg

## Provider Configuration

### DigitalOcean Setup

DigitalOcean is ideal for the Pterodactyl Panel due to reliable networking and managed databases.

#### 1. Create API Token
```bash
# Visit: https://cloud.digitalocean.com/account/api/tokens
# Click "Generate New Token"
# Name: "mgetf-terraform"
# Scopes: Read + Write
```

#### 2. Configure Terraform
```hcl
# terraform.tfvars
do_token = "dop_v1_your_token_here"

# Panel on DigitalOcean
panel_region      = "nyc3"  # or: sfo3, ams3, sgp1, lon1, fra1
panel_droplet_size = "s-2vcpu-4gb"  # $24/month

# Optional: DigitalOcean Managed Database
database_provider = "digitalocean_managed"
database_connection_string = "mysql://doadmin:password@db-mysql-nyc3-xxxxx.b.db.ondigitalocean.com:25060/panel?ssl-mode=REQUIRED"
```

#### 3. Available Regions
```hcl
# North America
"nyc1", "nyc3"  # New York
"sfo2", "sfo3"  # San Francisco
"tor1"          # Toronto

# Europe
"ams3"  # Amsterdam
"fra1"  # Frankfurt
"lon1"  # London

# Asia-Pacific
"sgp1"  # Singapore
"blr1"  # Bangalore
"syd1"  # Sydney
```

### Vultr Setup

Vultr offers better value for game servers with high-frequency CPUs.

#### 1. Create API Key
```bash
# Visit: https://my.vultr.com/settings/#settingsapi
# Click "Enable API"
# Copy Personal Access Token
```

#### 2. Configure Terraform
```hcl
# terraform.tfvars
vultr_api_key = "YOUR_VULTR_API_KEY"

wings_nodes = {
  west = {
    provider = "vultr"
    region   = "lax"          # Los Angeles
    size     = "vc2-2c-4gb"   # $18/month, High Frequency
    # or     = "vhf-2c-4gb"   # $24/month, Very High Frequency
  }
  central = {
    provider = "vultr"
    region   = "ord"          # Chicago
    size     = "vc2-2c-4gb"
  }
  east = {
    provider = "vultr"
    region   = "ewr"          # New Jersey
    size     = "vc2-2c-4gb"
  }
  europe = {
    provider = "vultr"
    region   = "ams"          # Amsterdam
    size     = "vc2-2c-4gb"
  }
}
```

#### 3. Vultr Regions
```hcl
# Americas
"ewr"  # New Jersey
"ord"  # Chicago
"dfw"  # Dallas
"sea"  # Seattle
"lax"  # Los Angeles
"atl"  # Atlanta
"mia"  # Miami

# Europe
"ams"  # Amsterdam
"lhr"  # London
"fra"  # Frankfurt
"par"  # Paris
"waw"  # Warsaw
"mad"  # Madrid
"sto"  # Stockholm

# Asia-Pacific
"nrt"  # Tokyo
"sgp"  # Singapore
"syd"  # Sydney
"icn"  # Seoul
"del"  # Delhi
```

### AWS/EC2 Setup

For existing AWS infrastructure or specific compliance requirements.

#### 1. Create IAM User
```bash
# Create user with EC2 permissions
aws iam create-user --user-name mgetf-terraform
aws iam attach-user-policy --user-name mgetf-terraform \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess
aws iam create-access-key --user-name mgetf-terraform
```

#### 2. Add AWS Provider
```hcl
# terraform/versions.tf (add to required_providers)
aws = {
  source  = "hashicorp/aws"
  version = "~> 5.0"
}

# terraform/main.tf (add provider)
provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
```
#### 3. Create AWS Wings Module
```hcl
# terraform/modules/wings-aws/main.tf
resource "aws_instance" "wings" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.wings.key_name
  
  vpc_security_group_ids = [aws_security_group.wings.id]
  
  user_data = templatefile("${path.module}/cloud-init.yaml", {
    node_name   = var.node_name
    panel_url   = var.panel_url
    panel_token = var.panel_token
  })
  
  tags = {
    Name        = "${var.project_name}-wings-${var.node_name}"
    Environment = var.environment
    Type        = "pterodactyl-wings"
  }
}

resource "aws_security_group" "wings" {
  name = "${var.project_name}-wings-${var.node_name}"
  
  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Wings daemon
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Game ports
  ingress {
    from_port   = 27015
    to_port     = 27020
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 27015
    to_port     = 27020
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
```

#### 4. Use in terraform.tfvars
```hcl
# AWS Configuration
aws_region     = "us-west-2"
aws_access_key = "AKIAXXXXXXXXXXXXXXXXX"
aws_secret_key = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

wings_nodes = {
  aws_west = {
    provider      = "aws"
    region        = "us-west-2"
    size          = "t3.medium"  # 2 vCPU, 4 GB RAM
    instance_type = "t3.medium"
  }
  aws_east = {
    provider      = "aws"
    region        = "us-east-1"
    size          = "t3.medium"
    instance_type = "t3.medium"
  }
}
```

### Linode Setup

Good balance of price and performance with dedicated CPU options.

#### 1. Create API Token
```bash
# Visit: https://cloud.linode.com/profile/tokens
# Click "Create a Personal Access Token"
# Label: mgetf-terraform
# Expiry: Never
# Scopes: Read/Write for Linodes, NodeBalancers, Domains
```

#### 2. Add Linode Provider
```hcl
# terraform/versions.tf
linode = {
  source  = "linode/linode"
  version = "~> 2.0"
}

# terraform/main.tf
provider "linode" {
  token = var.linode_token
}
```

#### 3. Create Linode Wings Module
```hcl
# terraform/modules/wings-linode/main.tf
resource "linode_instance" "wings" {
  label      = "${var.project_name}-wings-${var.node_name}"
  region     = var.region
  type       = var.instance_type
  image      = "linode/ubuntu22.04"
  root_pass  = random_password.root.result
  
  authorized_keys = [var.ssh_public_key]
  
  stackscript_id = linode_stackscript.wings_setup.id
  stackscript_data = {
    "panel_url"   = var.panel_url
    "panel_token" = var.panel_token
    "node_name"   = var.node_name
  }
}

resource "linode_stackscript" "wings_setup" {
  label       = "${var.project_name}-wings-setup"
  description = "Wings daemon setup for Pterodactyl"
  script      = file("${path.module}/setup.sh")
  images      = ["linode/ubuntu22.04"]
}
```

#### 4. Linode Configuration
```hcl
# terraform.tfvars
linode_token = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

wings_nodes = {
  linode_central = {
    provider      = "linode"
    region        = "us-central"  # Dallas
    size          = "g6-standard-2"  # 2 CPU, 4GB RAM, $20/mo
    instance_type = "g6-standard-2"
  }
  linode_west = {
    provider      = "linode"
    region        = "us-west"  # Fremont, CA
    size          = "g6-dedicated-2"  # 2 Dedicated CPU, 4GB, $30/mo
    instance_type = "g6-dedicated-2"
  }
}
```

## Self-Hosted Wings

Running Wings on your own hardware or home server provides complete control and potentially lower costs.

### Hardware Requirements

**Minimum (1-2 servers)**:
- CPU: 2+ cores, 2.4GHz+
- RAM: 4GB
- Storage: 50GB SSD
- Network: 100Mbps symmetric
- Static IP or Dynamic DNS

**Recommended (3-5 servers)**:
- CPU: 4+ cores, 3.0GHz+
- RAM: 8GB
- Storage: 100GB NVMe SSD
- Network: 1Gbps
- Static IP address

### Option 1: Direct Installation

#### Step 1: Prepare Your Server
```bash
# Update system (Ubuntu 22.04)
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sudo bash
sudo usermod -aG docker $USER

# Install required packages
sudo apt install -y curl wget software-properties-common

# Configure firewall
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 8080/tcp  # Wings API
sudo ufw allow 2022/tcp  # Wings SFTP
sudo ufw allow 27015:27020/tcp  # Game ports
sudo ufw allow 27015:27020/udp
sudo ufw --force enable
```

#### Step 2: Install Wings
```bash
# Create directory
sudo mkdir -p /etc/pterodactyl
cd /etc/pterodactyl

# Download Wings
sudo curl -L -o /usr/local/bin/wings \
  "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64"
sudo chmod +x /usr/local/bin/wings

# Create systemd service
sudo cat > /etc/systemd/system/wings.service <<EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
```

#### Step 3: Configure Wings

1. **In Pterodactyl Panel**:
   - Navigate to Admin → Nodes
   - Click "Create New"
   - Fill in:
     - Name: `home-server`
     - FQDN: Your IP or domain
     - Memory: Your RAM in MB
     - Disk: Your disk space in MB
   - Click "Create Node"
   - Go to Configuration tab
   - Click "Generate Token"

2. **On Your Server**:
```bash
# Get configuration from panel
cd /etc/pterodactyl

# Copy the configuration file content from panel
sudo nano config.yml
# Paste the configuration

# Start Wings
sudo systemctl enable --now wings
sudo systemctl status wings
```

### Option 2: Using Terraform (Existing Server)

For servers you already have SSH access to:

#### Step 1: Add to terraform.tfvars
```hcl
wings_nodes = {
  # ... other nodes ...
  
  home = {
    provider     = "custom"
    region       = "home"
    size         = "custom"
    public_ip    = "YOUR_PUBLIC_IP"  # or domain
    ssh_key_path = "~/.ssh/id_rsa"   # path to private key
  }
  
  colo = {
    provider     = "custom"
    region       = "datacenter"
    size         = "custom"
    public_ip    = "203.0.113.10"
    ssh_key_path = "~/.ssh/colo_key"
  }
}
```

#### Step 2: Create Custom Wings Module
```hcl
# terraform/modules/wings-custom/main.tf
resource "null_resource" "wings_custom" {
  connection {
    type        = "ssh"
    host        = var.public_ip
    user        = var.ssh_user
    private_key = file(var.ssh_key_path)
  }
  
  # Install Docker
  provisioner "remote-exec" {
    inline = [
      "curl -fsSL https://get.docker.com | sudo bash",
      "sudo usermod -aG docker ${var.ssh_user}"
    ]
  }
  
  # Copy Wings setup script
  provisioner "file" {
    source      = "${path.module}/install_wings.sh"
    destination = "/tmp/install_wings.sh"
  }
  
  # Install Wings
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_wings.sh",
      "sudo PANEL_URL=${var.panel_url} PANEL_TOKEN=${var.panel_token} bash /tmp/install_wings.sh"
    ]
  }
}
```

### Option 3: Home Server Behind NAT

For home servers without static IPs:

#### Step 1: Setup Dynamic DNS
```bash
# Using Cloudflare (free)
# 1. Add your domain to Cloudflare
# 2. Create A record: home.yourdomain.com → your current IP
# 3. Install ddclient:
sudo apt install ddclient

# Configure /etc/ddclient.conf:
protocol=cloudflare
use=web
web=https://api.ipify.org/
zone=yourdomain.com
ttl=1
login=your-cloudflare-email
password=your-cloudflare-api-token
home.yourdomain.com
```

#### Step 2: Port Forwarding

Configure your router to forward:
- TCP 8080 → Server:8080 (Wings API)
- TCP 2022 → Server:2022 (SFTP)
- TCP/UDP 27015-27020 → Server:27015-27020 (Game)

#### Step 3: Configure Panel

In Pterodactyl Panel, create node with:
- FQDN: `home.yourdomain.com`
- Behind Proxy: Yes (if using Cloudflare)

### Option 4: VPN Mesh Network

For maximum security and private servers:

#### Step 1: Enable VPN in Terraform
```hcl
# terraform.tfvars
enable_vpn  = true
vpn_network = "10.10.10.0/24"
```

#### Step 2: Manual WireGuard Setup
```bash
# On home server
sudo apt install wireguard

# Generate keys
wg genkey | tee privatekey | wg pubkey > publickey

# Configure /etc/wireguard/wg0.conf
[Interface]
PrivateKey = <your-private-key>
Address = 10.10.10.10/24
ListenPort = 51820

[Peer]
PublicKey = <panel-public-key>
Endpoint = panel.yourdomain.com:51820
AllowedIPs = 10.10.10.0/24
PersistentKeepalive = 25

# Start VPN
sudo wg-quick up wg0
sudo systemctl enable wg-quick@wg0
```

## Migration from Existing Infrastructure

### From Ansible/Manual Setup

If you have existing TF2 servers managed with Ansible or manually:

#### Step 1: Extract Configurations
```bash
# Run migration script
cd /path/to/mgetf/servers
./migrate_from_ansible.sh

# This extracts:
# - SourceMod plugins → migration_output/sm_plugins/
# - Server configs → migration_output/server.cfg
# - Database settings → migration_output/extracted_*.tfvars
```

#### Step 2: Build Custom Docker Image
```bash
cd migration_output

# Review extracted configs
ls -la

# Build custom egg with your configs
./build_custom_egg.sh

# Push to registry (GitHub Container Registry)
docker tag mgetf/tf2-mge:custom ghcr.io/YOUR_ORG/tf2-mge:custom
docker push ghcr.io/YOUR_ORG/tf2-mge:custom
```

#### Step 3: Update Terraform
```hcl
# terraform.tfvars
# Use your custom image
module "mge_egg" {
  source = "./modules/egg"
  # ...
  docker_image = "ghcr.io/YOUR_ORG/tf2-mge:custom"
}
```

### From Existing Docker Setup

If you already use Docker Compose:

```yaml
# Your docker-compose.yml
version: '3'
services:
  tf2-mge:
    image: your-image
    ports:
      - "27015:27015"
    volumes:
      - ./configs:/home/steam/configs
```

Convert to Pterodactyl egg:

1. Extract Dockerfile
2. Add Pterodactyl entrypoint
3. Create egg configuration
4. Import via Panel API

## Advanced Configuration

### Multi-Region Database Replication

For global deployments with low latency:

```hcl
# Use PlanetScale (MySQL-compatible, global replication)
database_provider = "planetscale"
database_connection_string = "mysql://xxxxx:pscale_pw_xxxxx@aws.connect.psdb.cloud/mgetf?ssl={'rejectUnauthorized':true}"

# Or Cloudflare D1 (SQLite at edge)
database_provider = "cloudflare-d1"
database_connection_string = "d1://your-database-id"
```

### Automatic Scaling

#### Weekend Scaling
```hcl
# terraform/weekend.tfvars
wings_nodes = {
  west = {
    provider = "vultr"
    region   = "lax"
    size     = "vc2-4c-8gb"  # Upgrade for weekend
  }
  west2 = {  # Additional weekend server
    provider = "vultr"
    region   = "lax"
    size     = "vc2-2c-4gb"
  }
  # ... existing nodes ...
}
```

```bash
# Cron job for automatic scaling
# Friday 6 PM - Scale up
0 18 * * 5 cd /path/to/terraform && terraform apply -var-file=weekend.tfvars -auto-approve

# Monday 2 AM - Scale down  
0 2 * * 1 cd /path/to/terraform && terraform apply -auto-approve
```

#### Player-Based Scaling

```python
#!/usr/bin/env python3
# auto_scale.py
import requests
import subprocess
from datetime import datetime

PANEL_API = "https://panel.mge.tf/api"
API_TOKEN = "your_token"
PLAYER_THRESHOLD = 20  # Players per server

def get_current_load():
    """Get current player count across all servers"""
    response = requests.get(
        f"{PANEL_API}/application/servers",
        headers={"Authorization": f"Bearer {API_TOKEN}"}
    )
    
    servers = response.json()['data']
    total_players = sum(s['current_players'] for s in servers)
    return total_players, len(servers)

def scale_servers():
    players, server_count = get_current_load()
    needed_servers = (players // PLAYER_THRESHOLD) + 1
    
    if needed_servers > server_count:
        # Scale up
        subprocess.run([
            "terraform", "apply",
            f"-var=server_count={needed_servers}",
            "-auto-approve"
        ])
    elif needed_servers < server_count - 1:  # Hysteresis
        # Scale down
        subprocess.run([
            "terraform", "apply", 
            f"-var=server_count={needed_servers}",
            "-auto-approve"
        ])

if __name__ == "__main__":
    scale_servers()
```

### Custom SourceMod Plugins

#### Adding to All Servers
```hcl
# terraform.tfvars
sourcemod_plugins = [
  "https://github.com/your/plugin1.git",
  "https://github.com/your/plugin2.git",
  "sm-whois",
  "mge_sockets"
]
```

#### Per-Server Plugins

Via Pterodactyl startup parameters:
1. Panel → Servers → Startup
2. Add variable: `CUSTOM_PLUGINS`
3. Value: `plugin1,plugin2`
4. Modify egg to load these plugins

### Monitoring & Observability

#### Enable Full Stack
```hcl
# terraform.tfvars
enable_monitoring = true

monitoring_config = {
  prometheus = true
  grafana    = true
  loki       = true  # Log aggregation
  tempo      = true  # Distributed tracing
}
```

#### Custom Dashboards

Create `terraform/modules/monitoring/dashboards/mge.json`:
```json
{
  "dashboard": {
    "title": "MGE.TF Server Metrics",
    "panels": [
      {
        "title": "Players Online",
        "targets": [{
          "expr": "sum(srcds_players_connected)"
        }]
      },
      {
        "title": "Server FPS",
        "targets": [{
          "expr": "avg(srcds_fps)"
        }]
      }
    ]
  }
}
```

### Security Hardening

#### Enable All Security Features
```hcl
# terraform.tfvars
security_config = {
  enable_vpn        = true
  enable_firewall   = true
  enable_fail2ban   = true
  enable_ids        = true  # Intrusion Detection
  ssl_only          = true
  force_2fa         = true  # Panel 2FA
}

# IP Allowlisting for admin
admin_ip_whitelist = [
  "203.0.113.0/24",  # Office
  "198.51.100.14",   # Home
]
```

## Troubleshooting

### Common Issues

#### Panel Can't Connect to Wings
```bash
# Check Wings status
systemctl status wings

# Check connectivity
curl -k https://node.domain.com:8080

# Check firewall
ufw status

# View Wings logs
journalctl -u wings -f
```

#### TF2 Server Won't Start
```bash
# Check via panel console
# Or SSH to Wings node:
docker ps -a
docker logs <container-id>

# Common fixes:
# 1. Steam token invalid
# 2. Ports already in use
# 3. Not enough memory allocated
```

#### Database Connection Issues
```bash
# Test connection
mysql -h <host> -u <user> -p<password> <database>

# For Cloudflare D1
wrangler d1 execute <database> --command "SELECT 1"
```

### Performance Optimization

#### Network Optimization
```bash
# On Wings nodes
# Enable BBR congestion control
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

# Increase network buffers
echo "net.core.rmem_max=134217728" >> /etc/sysctl.conf
echo "net.core.wmem_max=134217728" >> /etc/sysctl.conf
```

#### Storage Optimization
```bash
# Use XFS for game files
mkfs.xfs /dev/sdb1
mount -o noatime,nodiratime /dev/sdb1 /var/lib/pterodactyl

# Enable compression for logs
systemctl edit wings
# Add: Environment="WINGS_LOG_COMPRESS=true"
```

## Support & Resources

### Documentation
- **Pterodactyl**: https://pterodactyl.io/
- **Terraform**: https://developer.hashicorp.com/terraform
- **MGEMod**: https://github.com/maxijabase/MGEMod
- **SourceMod**: https://www.sourcemod.net/

### Community
- **Discord**: mge.tf dev channel
- **Forums**: https://forums.alliedmods.net/
- **Reddit**: r/tf2, r/truetf2

### Monitoring
- **Server Status**: https://status.mge.tf
- **Metrics**: https://grafana.mge.tf
- **Logs**: https://logs.mge.tf

## License

MIT License - See LICENSE file

## Contributors

- Tommy (tommyy_hla) - Project Lead
- Jason/Zod (zudsniper) - Infrastructure
- Ampere (amperetf) - MGEMod Development

---

*Built with ❤️ for the TF2 MGE community*