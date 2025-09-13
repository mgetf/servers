variable "project_name" {}
variable "domain" {}
variable "admin_email" {}
variable "droplet_size" {}
variable "region" {}
variable "ssh_key_id" {}
variable "ssh_private_key" { sensitive = true }
variable "database_provider" {}
variable "database_connection_string" { sensitive = true }
variable "enable_vpn" {}
variable "vpn_network" {}
variable "vpn_private_key" { sensitive = true }
variable "vpn_public_key" {}

# Panel droplet
resource "digitalocean_droplet" "panel" {
  name     = "${var.project_name}-panel"
  region   = var.region
  size     = var.droplet_size
  image    = "ubuntu-22-04-x64"
  ssh_keys = [var.ssh_key_id]
  tags     = ["pterodactyl", "panel", var.project_name]
  
  user_data = templatefile("${path.module}/cloud-init.yaml", {
    domain          = var.domain
    admin_email     = var.admin_email
    enable_vpn      = var.enable_vpn
    vpn_private_key = var.vpn_private_key
    vpn_network     = var.vpn_network
  })
}
# Panel provisioning
resource "null_resource" "panel_setup" {
  depends_on = [digitalocean_droplet.panel]
  
  connection {
    type        = "ssh"
    host        = digitalocean_droplet.panel.ipv4_address
    user        = "root"
    private_key = var.ssh_private_key
  }
  
  provisioner "remote-exec" {
    script = "${path.module}/scripts/install_panel.sh"
  }
  
  provisioner "remote-exec" {
    inline = [
      "export PANEL_DOMAIN=${var.domain}",
      "export ADMIN_EMAIL=${var.admin_email}",
      "export DB_PROVIDER=${var.database_provider}",
      "export DB_CONNECTION=${var.database_connection_string}",
      "bash /tmp/configure_panel.sh"
    ]
  }
}

# Generate API tokens
resource "random_password" "daemon_token" {
  length  = 32
  special = false
}

resource "random_password" "admin_api_token" {
  length  = 48
  special = false
}
