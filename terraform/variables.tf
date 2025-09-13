# Core configuration variables
variable "project_name" {
  description = "Project identifier"
  type        = string
  default     = "mgetf"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "vultr_api_key" {
  description = "Vultr API key"
  type        = string
  sensitive   = true
}

# Panel configuration
variable "panel_domain" {
  description = "FQDN for Pterodactyl panel"
  type        = string
  default     = "panel.mge.tf"
}

variable "panel_admin_email" {
  description = "Admin email for panel"
  type        = string
}

variable "panel_droplet_size" {
  description = "DigitalOcean droplet size for panel"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "panel_region" {
  description = "DigitalOcean region for panel"
  type        = string
  default     = "nyc3"
}

# Wings configuration
variable "wings_nodes" {
  description = "Wings node configurations"
  type = map(object({
    provider     = string  # "digitalocean" or "vultr"
    region       = string
    size         = string
    public_ip    = optional(string)  # For existing servers
    ssh_key_path = optional(string)
  }))
  default = {
    west = {
      provider = "vultr"
      region   = "lax"
      size     = "vc2-2c-4gb"
    }
    east = {
      provider = "vultr"
      region   = "ewr"
      size     = "vc2-2c-4gb"
    }
    home = {
      provider     = "custom"
      region       = "home"
      size         = "custom"
      public_ip    = "192.168.1.100"  # Replace with actual
      ssh_key_path = "~/.ssh/id_rsa"
    }
  }
}

# Database configuration
variable "database_provider" {
  description = "Database provider (local, cloudflare-d1, planetscale)"
  type        = string
  default     = "local"
}

variable "database_connection_string" {
  description = "External database connection string (if not local)"
  type        = string
  default     = ""
  sensitive   = true
}

# Network configuration
variable "enable_vpn" {
  description = "Enable WireGuard VPN for inter-node communication"
  type        = bool
  default     = true
}

variable "vpn_network" {
  description = "VPN network CIDR"
  type        = string
  default     = "10.10.10.0/24"
}

# Server configuration
variable "mgemod_repo" {
  description = "MGEMod repository URL"
  type        = string
  default     = "https://github.com/maxijabase/MGEMod"
}

variable "mgemod_branch" {
  description = "MGEMod branch"
  type        = string
  default     = "2v2"
}

variable "sourcemod_plugins" {
  description = "Additional SourceMod plugins to install"
  type        = list(string)
  default     = [
    "sm-whois",
    "mge_sockets"
  ]
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key for server access"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "enable_monitoring" {
  description = "Enable Prometheus/Grafana monitoring"
  type        = bool
  default     = false
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token for DNS management"
  type        = string
  default     = ""
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for mge.tf"
  type        = string
  default     = ""
}
