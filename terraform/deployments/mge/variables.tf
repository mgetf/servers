# ===========================================
# REQUIRED VARIABLES
# ===========================================

variable "compartment_id" {
  description = "The OCID of the OCI compartment to deploy into"
  type        = string
}

variable "rcon_password" {
  description = "RCON password for server administration"
  type        = string
  sensitive   = true
}

# ===========================================
# OPTIONAL VARIABLES
# ===========================================

variable "server_hostname" {
  description = "Server name shown in the server browser"
  type        = string
  default     = "MGE Training Server"
}

variable "server_token" {
  description = "Steam Game Server Login Token (GSLT) - get one at https://steamcommunity.com/dev/managegameservers"
  type        = string
  sensitive   = true
  default     = ""
}

