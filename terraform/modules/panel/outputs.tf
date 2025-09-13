output "public_ip" {
  value = digitalocean_droplet.panel.ipv4_address
}

output "daemon_token" {
  value     = random_password.daemon_token.result
  sensitive = true
}

output "admin_api_token" {
  value     = random_password.admin_api_token.result
  sensitive = true
}

output "panel_url" {
  value = "https://${var.domain}"
}

output "vpn_ip" {
  value = var.enable_vpn ? cidrhost(var.vpn_network, 1) : ""
}