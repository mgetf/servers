# Generate SSH key for Pterodactyl nodes
resource "tls_private_key" "pterodactyl" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "pterodactyl_key" {
  content         = tls_private_key.pterodactyl.private_key_pem
  filename        = "${path.module}/keys/pterodactyl_key.pem"
  file_permission = "0600"
}

# Create DigitalOcean SSH key
resource "digitalocean_ssh_key" "pterodactyl" {
  name       = "${var.project_name}-pterodactyl"
  public_key = tls_private_key.pterodactyl.public_key_openssh
}

# Create Vultr SSH key
resource "vultr_ssh_key" "pterodactyl" {
  name    = "${var.project_name}-pterodactyl"
  ssh_key = tls_private_key.pterodactyl.public_key_openssh
}

# Pterodactyl Panel Instance
module "panel" {
  source = "./modules/panel"
  
  project_name     = var.project_name
  domain          = var.panel_domain
  admin_email     = var.panel_admin_email
  droplet_size    = var.panel_droplet_size
  region          = var.panel_region
  ssh_key_id      = digitalocean_ssh_key.pterodactyl.id
  ssh_private_key = tls_private_key.pterodactyl.private_key_pem
  
  database_provider         = var.database_provider
  database_connection_string = var.database_connection_string
  
  enable_vpn  = var.enable_vpn
  vpn_network = var.vpn_network
  vpn_private_key = var.enable_vpn ? wireguard_asymmetric_key.panel[0].private_key : ""
  vpn_public_key  = var.enable_vpn ? wireguard_asymmetric_key.panel[0].public_key : ""
}

# WireGuard keys for VPN
resource "wireguard_asymmetric_key" "panel" {
  count = var.enable_vpn ? 1 : 0
}

resource "wireguard_asymmetric_key" "wings" {
  for_each = var.enable_vpn ? var.wings_nodes : {}
}

# Wings Nodes
module "wings" {
  source   = "./modules/wings"
  for_each = var.wings_nodes
  
  node_name        = each.key
  node_config      = each.value
  project_name     = var.project_name
  environment      = var.environment
  panel_url        = "https://${var.panel_domain}"
  panel_token      = module.panel.daemon_token
  ssh_key_id_do    = digitalocean_ssh_key.pterodactyl.id
  ssh_key_id_vultr = vultr_ssh_key.pterodactyl.id
  ssh_private_key  = tls_private_key.pterodactyl.private_key_pem
  
  enable_vpn      = var.enable_vpn
  vpn_network     = var.vpn_network
  vpn_private_key = var.enable_vpn ? wireguard_asymmetric_key.wings[each.key].private_key : ""
  vpn_public_key  = var.enable_vpn ? wireguard_asymmetric_key.wings[each.key].public_key : ""
  vpn_panel_public_key = var.enable_vpn ? wireguard_asymmetric_key.panel[0].public_key : ""
  vpn_panel_endpoint   = var.enable_vpn ? "${module.panel.public_ip}:51820" : ""
  
  mgemod_repo      = var.mgemod_repo
  mgemod_branch    = var.mgemod_branch
  sourcemod_plugins = var.sourcemod_plugins
}

# Custom Egg Creation
module "mge_egg" {
  source = "./modules/egg"
  
  panel_api_url   = "https://${var.panel_domain}/api"
  panel_api_token = module.panel.admin_api_token
  
  egg_name        = "TF2 MGE"
  egg_description = "Team Fortress 2 MGE server with custom MGEMod"
  docker_image    = "ghcr.io/mgetf/tf2-mge:latest"
  
  mgemod_repo   = var.mgemod_repo
  mgemod_branch = var.mgemod_branch
  
  depends_on = [module.panel]
}

# DNS Configuration (optional, if using Cloudflare)
resource "cloudflare_record" "panel" {
  count = var.cloudflare_zone_id != "" ? 1 : 0
  
  zone_id = var.cloudflare_zone_id
  name    = "panel"
  value   = module.panel.public_ip
  type    = "A"
  ttl     = 3600
}

resource "cloudflare_record" "wings" {
  for_each = var.cloudflare_zone_id != "" ? module.wings : {}
  
  zone_id = var.cloudflare_zone_id
  name    = "node-${each.key}"
  value   = each.value.public_ip
  type    = "A"
  ttl     = 3600
}
