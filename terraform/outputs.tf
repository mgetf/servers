output "panel_url" {
  description = "Pterodactyl Panel URL"
  value       = module.panel.panel_url
}

output "panel_ip" {
  description = "Panel server IP"
  value       = module.panel.public_ip
}

output "wings_nodes" {
  description = "Wings node IPs"
  value = {
    for k, v in module.wings : k => v.public_ip
  }
}

output "ssh_private_key" {
  description = "SSH private key for server access"
  value       = local_sensitive_file.pterodactyl_key.filename
  sensitive   = true
}

output "panel_admin_token" {
  description = "Panel admin API token"
  value       = module.panel.admin_api_token
  sensitive   = true
}

output "vpn_config" {
  description = "VPN configuration details"
  value = var.enable_vpn ? {
    network = var.vpn_network
    panel   = "${module.panel.vpn_ip}:51820"
    nodes   = { for k, v in module.wings : k => "${cidrhost(var.vpn_network, index(keys(var.wings_nodes), k) + 2)}:51820" }
  } : null
}