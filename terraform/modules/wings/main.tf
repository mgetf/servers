variable "node_name" {}
variable "node_config" {
  type = object({
    provider     = string
    region       = string
    size         = string
    public_ip    = optional(string)
    ssh_key_path = optional(string)
  })
}
variable "project_name" {}
variable "environment" {}
variable "panel_url" {}
variable "panel_token" { sensitive = true }
variable "ssh_key_id_do" {}
variable "ssh_key_id_vultr" {}
variable "ssh_private_key" { sensitive = true }
variable "enable_vpn" {}
variable "vpn_network" {}
variable "vpn_private_key" { sensitive = true }
variable "vpn_public_key" {}
variable "vpn_panel_public_key" {}
variable "vpn_panel_endpoint" {}
variable "mgemod_repo" {}
variable "mgemod_branch" {}
variable "sourcemod_plugins" { type = list(string) }

# Vultr instance
resource "vultr_instance" "wings" {
  count = var.node_config.provider == "vultr" ? 1 : 0
  
  plan     = var.node_config.size
  region   = var.node_config.region
  os_id    = 387  # Ubuntu 22.04
  label    = "${var.project_name}-wings-${var.node_name}"
  hostname = "${var.project_name}-wings-${var.node_name}"
  ssh_key_ids = [var.ssh_key_id_vultr]
  
  user_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    node_name    = var.node_name
    panel_url    = var.panel_url
    panel_token  = var.panel_token
    enable_vpn   = var.enable_vpn
    vpn_key      = var.vpn_private_key
    vpn_network  = var.vpn_network
  }))
}

# DigitalOcean instance
resource "digitalocean_droplet" "wings" {
  count = var.node_config.provider == "digitalocean" ? 1 : 0
  
  name     = "${var.project_name}-wings-${var.node_name}"
  region   = var.node_config.region
  size     = var.node_config.size
  image    = "ubuntu-22-04-x64"
  ssh_keys = [var.ssh_key_id_do]
  tags     = ["pterodactyl", "wings", var.project_name, var.node_name]
  
  user_data = templatefile("${path.module}/cloud-init.yaml", {
    node_name    = var.node_name
    panel_url    = var.panel_url
    panel_token  = var.panel_token
    enable_vpn   = var.enable_vpn
    vpn_key      = var.vpn_private_key
    vpn_network  = var.vpn_network
  })
}

# Provision Wings
resource "null_resource" "wings_setup" {
  depends_on = [vultr_instance.wings, digitalocean_droplet.wings]
  
  connection {
    type        = "ssh"
    host        = local.public_ip
    user        = "root"
    private_key = var.node_config.provider == "custom" ? file(var.node_config.ssh_key_path) : var.ssh_private_key
  }
  
  provisioner "file" {
    source      = "${path.module}/scripts/install_wings.sh"
    destination = "/tmp/install_wings.sh"
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_wings.sh",
      "PANEL_URL=${var.panel_url} PANEL_TOKEN=${var.panel_token} NODE_NAME=${var.node_name} bash /tmp/install_wings.sh"
    ]
  }
}

locals {
  public_ip = coalesce(
    var.node_config.provider == "vultr" ? try(vultr_instance.wings[0].main_ip, "") : "",
    var.node_config.provider == "digitalocean" ? try(digitalocean_droplet.wings[0].ipv4_address, "") : "",
    var.node_config.provider == "custom" ? var.node_config.public_ip : ""
  )
}

output "public_ip" {
  value = local.public_ip
}

output "node_id" {
  value = coalesce(
    try(vultr_instance.wings[0].id, ""),
    try(digitalocean_droplet.wings[0].id, ""),
    var.node_name
  )
}