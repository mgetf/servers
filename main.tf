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

resource "vultr_instance" "game_server" {
  plan      = "vc2-2c-4gb" # 2 CPU, 4GB RAM, $20/mo
  region    = "chi"        # Frankfurt, adjust as needed
  os_id     = 2284          # Ubuntu 22.04
  hostname  = "tf2-node"
  label     = "Game Server"
  # Bootstrap Babashka, nREPL, and basic deps
  user_data = <<EOF
#!/bin/bash
apt update && apt install -y curl git
curl -sL https://raw.githubusercontent.com/babashka/babashka/master/install | bash
echo "(require '[babashka.nrepl.server :as nrepl]) (nrepl/start-server :port 1337 :bind \"0.0.0.0\")" > /root/repl.clj
bb /root/repl.clj &
EOF
  firewall_group_id = vultr_firewall_group.game_server_fw.id
}


resource "vultr_block_storage" "tf2_data" {
  size_gb     = 100
  region      = "chi"
  attached_to_instance = vultr_instance.game_server.id
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

resource "vultr_firewall_rule" "tf2" {
  firewall_group_id = vultr_firewall_group.game_server_fw.id
  protocol          = "udp"
  port              = "27015" # TF2 default port
  subnet            = "0.0.0.0"
  subnet_size       = 0
  ip_type          = "v4"
}

resource "vultr_firewall_rule" "tf2_stv" {
  firewall_group_id = vultr_firewall_group.game_server_fw.id
  protocol          = "udp"
  port              = "27020"
  subnet            = "0.0.0.0"
  subnet_size       = 0
  ip_type          = "v4"
}

output "server_ip" {
  value = vultr_instance.game_server.main_ip
}
