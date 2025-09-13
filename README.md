# MGE.TF Servers

Modern infrastructure deployment for Team Fortress 2 MGE servers using Pterodactyl Panel and Terraform.

## 📚 Documentation

- **[Quick Start Guide](README_QUICKSTART.md)** - Get running in 5 minutes
- **[Complete Infrastructure Documentation](README_INFRASTRUCTURE.md)** - Full details on architecture, providers, and configuration
- **[Troubleshooting Guide](TROUBLESHOOTING.md)** - Common issues and solutions
- **[Migration Guide](migrate_from_ansible.sh)** - Script to migrate from existing Ansible setups

## 🎯 What This Is

A complete infrastructure-as-code solution for deploying and managing TF2 MGE servers globally with:
- Web-based management panel (Pterodactyl)
- Multi-region server deployment
- Automatic updates and maintenance
- Cost-optimized scaling
- Modern DevOps practices

## 🚀 Quick Deploy

```bash
# 1. Configure
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Add your API keys

# 2. Deploy
terraform init && terraform apply

# 3. Create admin
ssh -i keys/pterodactyl_key.pem root@PANEL_IP
cd /var/www/pterodactyl && php artisan p:user:create

# 4. Access panel at https://panel.mge.tf
```

## 📁 Repository Structure

```
mgetf/servers/
├── terraform/                 # Infrastructure as Code
│   ├── main.tf               # Core infrastructure
│   ├── variables.tf          # Configuration options
│   ├── terraform.tfvars.example  # Example configuration
│   └── modules/              # Reusable components
│       ├── panel/            # Pterodactyl Panel setup
│       ├── wings/            # Game server nodes
│       └── egg/              # TF2 MGE server template
├── docker/                   # Container definitions
│   ├── Dockerfile            # TF2 MGE server image
│   └── entrypoint.sh         # Container startup script
├── ansible/                  # Legacy Ansible configs (reference)
├── migrate_from_ansible.sh   # Migration tool
└── .github/workflows/        # CI/CD pipelines
```

## 🏗️ Architecture

```
Internet → Pterodactyl Panel (Web UI)
              ↓
         Wings Nodes (Multiple Regions)
              ↓
         Docker Containers (TF2 Servers)
```

## 🌍 Supported Providers

- **DigitalOcean** - Panel hosting
- **Vultr** - Game server nodes
- **AWS EC2** - Enterprise deployments
- **Linode** - Alternative provider
- **Self-hosted** - Your own hardware

## 💰 Costs

- **Minimal**: ~$42/month (Panel + 1 node)
- **Standard**: ~$60/month (Panel + 2 nodes)
- **Global**: ~$100/month (Panel + 4 nodes)

## 🛠️ Features

### Current
- ✅ Automated deployment via Terraform
- ✅ Multi-region support
- ✅ Pterodactyl Panel integration
- ✅ Docker containerization
- ✅ MGEMod 2v2 support (Ampere's fork)
- ✅ Automatic SSL certificates
- ✅ VPN mesh networking (optional)
- ✅ Migration from Ansible

### Planned
- 🔄 Auto-scaling based on player count
- 🔄 Tournament system integration
- 🔄 WebSocket control API
- 🔄 Advanced monitoring/metrics
- 🔄 Automated backups

## 👥 Team

- **Tommy** (tommyy_hla) - Project Lead & Funding
- **Jason/Zod** (zudsniper) - Infrastructure Engineer
- **Ampere** (amperetf) - MGEMod Developer

## 📞 Support

- **Discord**: mge.tf dev channel
- **Issues**: [GitHub Issues](https://github.com/mgetf/servers/issues)
- **Email**: admin@mge.tf

## 📄 License

MIT License - See [LICENSE](LICENSE.md)

---

*Originally forked from [leighmacdonald/uncletopia](https://github.com/leighmacdonald/uncletopia) Ansible playbooks*