# ===========================================
# OUTPUTS
# ===========================================

output "server_ip" {
  description = "Public IP address of the MGE server"
  value       = module.mge_server.public_ip
}

output "connect_command" {
  description = "Command to connect to the server"
  value       = "connect ${module.mge_server.public_ip}:27015"
}

