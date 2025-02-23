terraform {
    required_providers {
        vultr = {
            source = "vultr/vultr"
            version = "2.23.1"
        }
    }
}

provider "vultr" {
    api_key = var.vultr_api_key
}

variable "vultr_api_key" {
  description = "Vultr API key"
  sensitive   = true
}

variable "ssh_key_id" {
  description = "Vultr SSH key ID"
  type        = string
}

locals {
  servers = {
    eu = {
      region   = "fra"      # Frankfurt
      hostname = "tf2-eu"
      label    = "TF2 EU Server"
    }
    us = {
      region   = "ord"      # Chicago
      hostname = "tf2-us"
      label    = "TF2 US Server"
    }
  }
}

resource "vultr_instance" "game_server" {
  for_each   = local.servers
  plan       = "vc2-2c-4gb-intel"
  region     = each.value.region
  os_id      = 2284          # Ubuntu 22.04
  hostname   = each.value.hostname
  label      = each.value.label
  ssh_key_ids = [var.ssh_key_id]
  user_data  = <<EOF
#!/bin/bash
# Disable UFW since we're using Vultr's firewall
ufw disable

# Install basic dependencies
apt update && apt install -y git

# Clone your repository (replace with your actual repo URL)
git clone https://github.com/mgetf/servers.git /opt/tf2-server
cd /opt/tf2-server

# Make the setup script executable and run it
chmod +x setup.sh
./setup.sh
EOF
  firewall_group_id = vultr_firewall_group.game_server_fw.id
}

resource "vultr_firewall_group" "game_server_fw" {
  description = "Firewall for TF2/Node server"
}

resource "vultr_firewall_rule" "ssh" {
  firewall_group_id = vultr_firewall_group.game_server_fw.id
  protocol          = "tcp"
  port              = "22"
  subnet            = "0.0.0.0"
  subnet_size       = 0
  ip_type          = "v4"
}

resource "vultr_firewall_rule" "nrepl" {
  firewall_group_id = vultr_firewall_group.game_server_fw.id
  protocol          = "tcp"
  port              = "1337"
  subnet            = "0.0.0.0"
  subnet_size       = 0
  ip_type          = "v4"
}

resource "vultr_firewall_rule" "tf2_main" {
  firewall_group_id = vultr_firewall_group.game_server_fw.id
  protocol          = "udp"
  port              = "27015"  # Main game connection port (required)
  subnet            = "0.0.0.0"
  subnet_size       = 0
  ip_type          = "v4"
}

resource "vultr_firewall_rule" "tf2_rcon" {
  firewall_group_id = vultr_firewall_group.game_server_fw.id
  protocol          = "tcp"
  port              = "27015"  # RCON port
  subnet            = "0.0.0.0"
  subnet_size       = 0
  ip_type          = "v4"
}

resource "vultr_firewall_rule" "tf2_stv" {
  firewall_group_id = vultr_firewall_group.game_server_fw.id
  protocol          = "udp"
  port              = "27020"  # SourceTV port
  subnet            = "0.0.0.0"
  subnet_size       = 0
  ip_type          = "v4"
}

output "server_ips" {
  value = {
    for k, v in vultr_instance.game_server : k => v.main_ip
  }
}
