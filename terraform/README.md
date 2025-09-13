# MGE.TF Infrastructure

Terraform-based deployment for Pterodactyl Panel + Wings with custom TF2 MGE servers.

## Architecture

```
┌─────────────────┐       ┌──────────────────────┐
│  Pterodactyl    │◄──────│  Wings Node (West)   │
│  Panel (DO)     │       │  Vultr LAX           │
│                 │       └──────────────────────┘
│  - Web UI       │       ┌──────────────────────┐
│  - API          │◄──────│  Wings Node (East)   │
│  - Database     │       │  Vultr EWR           │
└─────────────────┘       └──────────────────────┘
         ▲                ┌──────────────────────┐
         └────────────────│  Wings Node (Home)   │
                          │  Custom/On-prem      │
                          └──────────────────────┘
```

## Quick Start

1. **Prerequisites**
   - Terraform >= 1.5
   - DigitalOcean API token
   - Vultr API key
   - Domain pointed to Cloudflare (optional)

2. **Setup**
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your credentials
   
   terraform init
   terraform plan
   terraform apply
   ```

3. **Access Panel**
   - URL: `https://panel.mge.tf` (or configured domain)
   - Initial admin setup: SSH to panel server
   ```bash
   ssh root@<panel-ip> -i terraform/keys/pterodactyl_key.pem
   cd /var/www/pterodactyl
   php artisan p:user:create
   ```

## Configuration

### terraform.tfvars

```hcl
# Required
do_token          = "your-digitalocean-token"
vultr_api_key     = "your-vultr-api-key"
panel_admin_email = "admin@mge.tf"

# Wings nodes
wings_nodes = {
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
  # Custom/existing server
  home = {
    provider     = "custom"
    region       = "home"
    size         = "custom"
    public_ip    = "192.168.1.100"
    ssh_key_path = "~/.ssh/id_rsa"
  }
}

# VPN (recommended)
enable_vpn  = true
vpn_network = "10.10.10.0/24"

# Database options
database_provider = "local"  # or "cloudflare-d1", "planetscale"
# database_connection_string = "mysql://..." # for external DB

# MGEMod settings
mgemod_repo   = "https://github.com/maxijabase/MGEMod"
mgemod_branch = "2v2"
```

### Adding Servers via Panel

1. Login to Pterodactyl panel
2. Navigate to Servers → Create Server
3. Select TF2 MGE egg
4. Configure:
   - Server name
   - Memory/CPU allocation
   - Startup map (default: mge_training_v8_beta4b)
   - Max players (2-32)
   - RCON password
   - Steam Game Server Token

## Custom Egg Features

The TF2 MGE egg includes:
- Latest TF2 dedicated server
- Metamod:Source + SourceMod
- Ampere's MGEMod fork with 2v2 support
- Pre-configured for MGE gameplay
- Popular MGE maps pre-installed
- SQLite database (upgradeable to MySQL/Postgres)

### Extending with Plugins

Add SourceMod plugins to `sourcemod_plugins` variable:
```hcl
sourcemod_plugins = [
  "sm-whois",      # Player tracking
  "mge_sockets",   # WebSocket control
  "your-plugin"
]
```

## Ansible Integration

Existing Ansible configs adapted for containerized deployment:

1. **Preserved Components**
   - SourceMod compilation pipeline
   - Plugin configurations
   - Server configs

2. **Removed (handled by Pterodactyl)**
   - Direct SRCDS management
   - systemd services
   - Manual updates

3. **Modified**
   - Database connections (now configurable)
   - Network settings (container-aware)
   - Resource paths

### Migration from Uncletopia Fork

```bash
# Extract necessary configs
ansible-playbook extract_configs.yml

# Build custom egg with configs
cd docker
docker build -t ghcr.io/mgetf/tf2-mge:latest .
docker push ghcr.io/mgetf/tf2-mge:latest

# Deploy via Terraform
terraform apply
```

## API Automation

Pterodactyl API for server management:

```bash
# Create server via API
curl -X POST https://panel.mge.tf/api/application/servers \
  -H "Authorization: Bearer ${PANEL_TOKEN}" \
  -H "Content-Type: application/json" \
  -d @server_config.json

# Scale servers (weekend peak)
terraform apply -var='wings_nodes={"west":{...},"west2":{...}}'
```

### Dynamic Scaling Script

```python
#!/usr/bin/env python3
import requests
from datetime import datetime

API_URL = "https://panel.mge.tf/api"
API_TOKEN = "your-token"

def scale_for_weekend():
    if datetime.now().weekday() >= 5:  # Weekend
        # Create additional servers
        create_server("mge-weekend-1", node="west")
        create_server("mge-weekend-2", node="east")
    else:
        # Remove weekend servers
        delete_server("mge-weekend-1")
        delete_server("mge-weekend-2")
```

## Monitoring (Optional)

Enable monitoring in terraform.tfvars:
```hcl
enable_monitoring = true
```

Deploys:
- Prometheus (metrics collection)
- Grafana (visualization)
- Node exporters on all servers

## Security

- WireGuard VPN for inter-node communication
- UFW firewall with strict rules
- SSL via Let's Encrypt
- API tokens in Terraform state (use remote backend)
- SSH keys auto-generated

## Troubleshooting

### Panel Issues
```bash
ssh root@<panel-ip>
journalctl -u nginx -f
cd /var/www/pterodactyl
php artisan queue:work
```

### Wings Issues
```bash
ssh root@<wings-ip>
systemctl status wings
journalctl -u wings -f
cat /etc/pterodactyl/config.yml
```

### TF2 Server Issues
- Check via Panel → Servers → Console
- SSH to Wings node: `docker ps`
- Logs: `docker logs <container-id>`

## Directory Structure

```
mgetf/servers/
├── terraform/
│   ├── main.tf              # Core infrastructure
│   ├── variables.tf         # Configuration options
│   ├── outputs.tf           # Deployment outputs
│   ├── modules/
│   │   ├── panel/           # Pterodactyl Panel
│   │   ├── wings/           # Wings nodes
│   │   └── egg/             # Custom TF2 MGE egg
│   └── keys/                # Generated SSH keys
├── docker/
│   ├── Dockerfile           # TF2 MGE container
│   └── entrypoint.sh        # Container startup
├── ansible/                 # Legacy configs (reference)
└── .github/workflows/       # CI/CD pipelines
```

## Next Steps

1. **Production Readiness**
   - Configure Terraform remote state (S3/Terraform Cloud)
   - Setup backup strategy for panel database
   - Configure monitoring/alerting

2. **Advanced Features**
   - WebSocket plugin for real-time control
   - Tournament system integration
   - Stats API for mge.tf website
   - Automated demo processing

3. **Cost Optimization**
   - Implement auto-scaling based on player count
   - Use reserved instances for baseline capacity
   - Spot instances for peak loads

## Support

- Panel docs: https://pterodactyl.io/panel/1.0/getting_started.html
- Wings docs: https://pterodactyl.io/wings/1.0/installing.html
- MGEMod: https://github.com/maxijabase/MGEMod
- Discord: mge.tf dev channel