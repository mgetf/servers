# ===========================================
# MGE SERVER DEPLOYMENT
# ===========================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0"
    }
  }

  # Uncomment and configure for remote state
  # backend "s3" {
  #   bucket   = "your-terraform-state-bucket"
  #   key      = "mge-server/terraform.tfstate"
  #   region   = "us-ashburn-1"
  #   endpoint = "https://<namespace>.compat.objectstorage.<region>.oraclecloud.com"
  # }
}

# ===========================================
# PROVIDER CONFIGURATION
# ===========================================

provider "oci" {
  # Configure via environment variables or config file:
  # - OCI_TENANCY_OCID
  # - OCI_USER_OCID
  # - OCI_FINGERPRINT
  # - OCI_PRIVATE_KEY_PATH
  # - OCI_REGION
}

# ===========================================
# SHARED INFRASTRUCTURE
# ===========================================

module "network" {
  source = "../../modules/network"

  compartment_id    = var.compartment_id
  name_prefix       = "mge"
  vcn_cidr_block    = "10.0.0.0/16"
  subnet_cidr_block = "10.0.1.0/24"
}

module "iam" {
  source = "../../modules/iam"

  compartment_id = var.compartment_id
  name_prefix    = "mge"
}

# ===========================================
# MGE SERVER
# ===========================================

module "mge_server" {
  source = "../../modules/tf2-server"

  compartment_id      = var.compartment_id
  server_name         = "mge-server"
  availability_domain = module.network.availability_domain
  subnet_id           = module.network.subnet_id
  nsg_ids             = [module.network.nsg_id]

  # YOUR custom MGE image - auto-updates on every push to main
  tf2_image     = "ghcr.io/mgetf/tf2-mge"
  tf2_image_tag = "main"

  # Container resources
  container_shape         = "CI.Standard.E4.Flex"
  container_ocpus         = 1
  container_memory_in_gbs = 4

  # Server configuration
  server_hostname = var.server_hostname
  server_token    = var.server_token
  rcon_password   = var.rcon_password

  depends_on = [module.iam]
}

