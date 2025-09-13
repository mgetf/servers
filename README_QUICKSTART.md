# MGE.TF Server Infrastructure - Quick Start

For full documentation, see [README_INFRASTRUCTURE.md](README_INFRASTRUCTURE.md)

## 5-Minute Setup

### Prerequisites
- DigitalOcean account with API token
- Vultr account with API key  
- Domain name (optional but recommended)
- Terraform installed (`brew install terraform` on macOS)

### Step 1: Configure
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

**Minimum configuration**:
```hcl
# API Keys (required)
do_token      = "dop_v1_your_token"
vultr_api_key = "YOUR_VULTR_KEY"

# Admin email (required)
panel_admin_email = "you@email.com"

# Panel domain (use IP if no domain)
panel_domain = "panel.mge.tf"
```

### Step 2: Deploy
```bash
terraform init
terraform apply
# Type 'yes' when prompted
# Wait ~10 minutes for deployment
```

### Step 3: Create Admin
```bash
# SSH to panel (IP shown in terraform output)
ssh -i keys/pterodactyl_key.pem root@PANEL_IP

# Create admin user
cd /var/www/pterodactyl
php artisan p:user:create
# Enter: email, username, password
```

### Step 4: Access Panel
1. Open browser: `https://panel.mge.tf` (or IP address)
2. Login with admin credentials
3. Create server: Servers → Create New → Select "TF2 MGE" egg

## Common Configurations

### Just West Coast (Tommy's Request)
```hcl
wings_nodes = {
  west = {
    provider = "vultr"
    region   = "lax"
    size     = "vc2-2c-4gb"
  }
}
```

### West + East Coast
```hcl
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
}
```

### Add Your Home Server
```hcl
wings_nodes = {
  # ... other nodes ...
  home = {
    provider     = "custom"
    region       = "home"
    size         = "custom"
    public_ip    = "192.168.1.100"  # Your server IP
    ssh_key_path = "~/.ssh/id_rsa"
  }
}
```

## Quick Commands

```bash
# View all resources
terraform state list

# Get panel URL
terraform output panel_url

# Get SSH key location
terraform output ssh_private_key

# Destroy everything (careful!)
terraform destroy

# Update only panel
terraform apply -target=module.panel

# Update specific wings node
terraform apply -target=module.wings["west"]
```

## Costs

**Monthly estimates**:
- Panel (DigitalOcean): $24/month
- Wings node (Vultr): $18/month each
- Total (1 panel + 2 nodes): ~$60/month

**Ways to reduce costs**:
- Use single Wings node: ~$42/month
- Self-host Wings on existing server: ~$24/month
- Use spot/preemptible instances
- Scale down during off-peak

## Need Help?

- Full docs: [README_INFRASTRUCTURE.md](README_INFRASTRUCTURE.md)
- Discord: mge.tf dev channel
- Issues: GitHub issues

## What This Creates

```
┌──────────────┐
│   Panel      │ ← Web UI for managing servers
│ (DigitalOcean)│
└──────┬───────┘
       │
   ┌───┴───┐
   ▼       ▼
┌──────┐ ┌──────┐
│Wings │ │Wings │ ← Actual game servers run here
│West  │ │East  │
└──────┘ └──────┘
```

Each Wings node can host multiple TF2 servers, managed through the web panel.