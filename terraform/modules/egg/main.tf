variable "panel_api_url" {}
variable "panel_api_token" { sensitive = true }
variable "egg_name" {}
variable "egg_description" {}
variable "docker_image" {}
variable "mgemod_repo" {}
variable "mgemod_branch" {}

# Create custom egg via Pterodactyl API
resource "null_resource" "create_egg" {
  provisioner "local-exec" {
    command = <<-EOT
      curl -X POST "${var.panel_api_url}/application/nests/1/eggs" \
        -H "Authorization: Bearer ${var.panel_api_token}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -d @${path.module}/egg_config.json
    EOT
  }
  
  triggers = {
    egg_config = filemd5("${path.module}/egg_config.json")
  }
}

# Generate egg configuration
resource "local_file" "egg_config" {
  filename = "${path.module}/egg_config.json"
  content = jsonencode({
    name        = var.egg_name
    description = var.egg_description
    docker_images = {
      default = var.docker_image
    }
    startup = "cd /home/container && ./srcds_run -game tf -console -port {{SERVER_PORT}} +map {{STARTUP_MAP}} +maxplayers {{MAX_PLAYERS}} +sv_setsteamaccount {{STEAM_ACC}}"
    config = {
      files = {
        "tf/cfg/server.cfg" = {
          parser = "properties"
          find = {
            "hostname"       = "{{server.build.env.SERVER_NAME}}"
            "rcon_password"  = "{{server.build.env.RCON_PASSWORD}}"
            "sv_password"    = "{{server.build.env.SERVER_PASSWORD}}"
            "maxplayers"     = "{{server.build.env.MAX_PLAYERS}}"
          }
        }
      }
      startup = {
        done = "VAC secure mode is activated"
      }
      logs = {}
      stop = "quit"
    }
    scripts = {
      installation = {
        script = file("${path.module}/install_script.sh")
        container = "ghcr.io/parkervcp/installers:debian"
        entrypoint = "bash"
      }
    }
    variables = [
      {
        name         = "Startup Map"
        description  = "The map to start the server on"
        env_variable = "STARTUP_MAP"
        default_value = "mge_training_v8_beta4b"
        user_viewable = true
        user_editable = true
        rules        = "required|string|max:64"
      },
      {
        name         = "Max Players"
        description  = "Maximum number of players"
        env_variable = "MAX_PLAYERS"
        default_value = "24"
        user_viewable = true
        user_editable = true
        rules        = "required|numeric|between:2,32"
      },
      {
        name         = "Server Name"
        description  = "Server hostname"
        env_variable = "SERVER_NAME"
        default_value = "MGE.TF Server"
        user_viewable = true
        user_editable = true
        rules        = "required|string|max:128"
      },
      {
        name         = "RCON Password"
        description  = "Remote console password"
        env_variable = "RCON_PASSWORD"
        default_value = ""
        user_viewable = true
        user_editable = true
        rules        = "nullable|string|max:64"
      },
      {
        name         = "Server Password"
        description  = "Password to join server"
        env_variable = "SERVER_PASSWORD"
        default_value = ""
        user_viewable = true
        user_editable = true
        rules        = "nullable|string|max:64"
      },
      {
        name         = "Steam Account Token"
        description  = "Steam Game Server Login Token"
        env_variable = "STEAM_ACC"
        default_value = ""
        user_viewable = true
        user_editable = true
        rules        = "nullable|string|max:64"
      }
    ]
  })
}

output "egg_id" {
  value = null_resource.create_egg.id
}