terraform {
  required_version = ">= 1.5"
  
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.34"
    }
    vultr = {
      source  = "vultr/vultr"
      version = "~> 2.19"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
  
  # Optional: Configure state backend for team collaboration
  # backend "s3" {
  #   bucket = "mgetf-terraform-state"
  #   key    = "infrastructure/terraform.tfstate"
  #   region = "us-west-2"
  # }
}

# Provider configurations
provider "digitalocean" {
  token = var.do_token
}

provider "vultr" {
  api_key = var.vultr_api_key
}
