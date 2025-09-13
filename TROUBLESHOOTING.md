# MGE.TF Infrastructure - Troubleshooting Guide

## Common Issues & Solutions

### Terraform Issues

#### "Error: Error creating droplet: POST https://api.digitalocean.com/v2/droplets: 401"
**Cause**: Invalid or expired DigitalOcean token
**Solution**:
```bash
# Verify token is correct in terraform.tfvars
# Get new token from: https://cloud.digitalocean.com/account/api/tokens
do_token = "dop_v1_xxxxxxxxxxxxx"
```

#### "Error: Invalid provider configuration"
**Cause**: Missing required provider credentials
**Solution**:
```bash
# Ensure all required variables are set
terraform plan  # Will show missing variables
# Check terraform.tfvars has all required fields
```

#### "Error acquiring the state lock"
**Cause**: Previous terraform operation was interrupted
**Solution**:
```bash
# Force unlock (use ID from error message)
terraform force-unlock <lock-id>
# Or remove lock file
rm .terraform.lock.hcl
terraform init
```

### Panel Issues

#### Can't Access Panel Web UI
**Symptoms**: Browser shows connection refused or timeout
**Solutions**:
```bash
# 1. Check if panel is running
ssh -i terraform/keys/pterodactyl_key.pem root@PANEL_IP
systemctl status nginx
systemctl status php8.2-fpm

# 2. Check firewall
ufw status
# Should show 80/tcp and 443/tcp ALLOW

# 3. Check DNS (if using domain)
nslookup panel.yourdomain.com
# Should return panel IP

# 4. Check SSL certificate
certbot certificates
# Renew if needed
certbot renew
```

#### Panel Shows 500 Error
**Cause**: Database or configuration issue
**Solutions**:
```bash
# Check logs
tail -f /var/www/pterodactyl/storage/logs/laravel-*.log

# Clear cache
cd /var/www/pterodactyl
php artisan cache:clear
php artisan config:clear
php artisan view:clear

# Check database connection
php artisan tinker
>>> DB::connection()->getPdo();

# Regenerate key if needed
php artisan key:generate --force
```

#### Can't Create Admin User
**Error**: "Class 'User' not found"
**Solution**:
```bash
cd /var/www/pterodactyl
composer install --no-dev
php artisan migrate --seed --force
php artisan p:user:create
```

### Wings Issues

#### Wings Won't Connect to Panel
**Symptoms**: Node shows as offline in panel
**Solutions**:
```bash
# 1. Check Wings is running
ssh -i terraform/keys/pterodactyl_key.pem root@WINGS_IP
systemctl status wings

# 2. Check configuration
cat /etc/pterodactyl/config.yml
# Verify panel URL and token are correct

# 3. Test connectivity to panel
curl -k https://panel.yourdomain.com/api/application/nodes

# 4. Regenerate node configuration
# In Panel: Nodes → Your Node → Configuration → Generate Token
# Copy new config to /etc/pterodactyl/config.yml
systemctl restart wings

# 5. Check logs
journalctl -u wings -f
```

#### "Error: Cannot connect to the Docker daemon"
**Cause**: Docker not running on Wings node
**Solution**:
```bash
systemctl start docker
systemctl enable docker
# Verify Docker works
docker run hello-world
```

#### Wings API Port Already in Use
**Error**: "listen tcp :8080: bind: address already in use"
**Solution**:
```bash
# Find what's using port 8080
lsof -i :8080
# Kill the process or change Wings port in config.yml
```

### TF2 Server Issues

#### Server Won't Start
**Check via Panel Console or SSH**:
```bash
# Find container
docker ps -a | grep tf2

# Check logs
docker logs <container-id>

# Common issues:
# 1. Invalid Steam token
# 2. Port conflict
# 3. Not enough memory allocated
# 4. Missing game files
```

#### "Missing map mge_training_v8_beta4b"
**Cause**: Map download failed during installation
**Solution**:
```bash
# Manual download
cd /var/lib/pterodactyl/volumes/<server-uuid>/tf/maps
wget https://fastdl.mge.tf/maps/mge_training_v8_beta4b.bsp
```

#### High Ping/Lag Issues
**Solutions**:
```bash
# 1. Check server performance
docker stats <container-id>

# 2. Network optimization (on Wings node)
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
sysctl -p

# 3. Check CPU governor
cpupower frequency-info
cpupower frequency-set -g performance

# 4. Verify server rates in server.cfg
sv_maxrate 0
sv_minrate 100000
sv_maxcmdrate 66
sv_maxupdaterate 66
```

#### SourceMod Not Loading
**Check**:
```bash
# In game console or RCON
sm version
meta list

# If not loaded, check paths
ls -la tf/addons/metamod/
ls -la tf/addons/sourcemod/
```

### Database Issues

#### "SQLSTATE[HY000] [2002] Connection refused"
**Cause**: Database server not running or misconfigured
**Solutions**:
```bash
# For local database
systemctl start mariadb
systemctl enable mariadb

# Test connection
mysql -u pterodactyl -p panel

# For external database
# Verify connection string in .env
cd /var/www/pterodactyl
nano .env
# DB_HOST=localhost
# DB_PORT=3306
# DB_DATABASE=panel
# DB_USERNAME=pterodactyl
# DB_PASSWORD=yourpassword
```

#### Database Migration Failed
**Solution**:
```bash
cd /var/www/pterodactyl
php artisan migrate:fresh --seed
# WARNING: This will reset the database!
```

### Network/VPN Issues

#### WireGuard VPN Not Connecting
**Check**:
```bash
# Status
wg show

# Logs
journalctl -u wg-quick@wg0

# Common fixes
# 1. Check firewall allows UDP 51820
ufw allow 51820/udp

# 2. Verify keys match
wg show wg0 public-key  # On panel
# Should match peer public key on wings

# 3. Restart interface
wg-quick down wg0
wg-quick up wg0
```

### Self-Hosted Issues

#### Can't Connect from Outside Network
**Checklist**:
1. **Port forwarding configured on router?**
   - 8080 TCP (Wings API)
   - 2022 TCP (SFTP)
   - 27015-27020 TCP/UDP (Game)

2. **Firewall allows connections?**
```bash
ufw status
```

3. **Dynamic DNS updated?**
```bash
nslookup yourdomain.com
# Should show your current IP
```

4. **ISP blocking ports?**
```bash
# Test from external network
nc -zv your-ip 8080
```

### Scaling Issues

#### Out of Memory on Wings Node
**Symptoms**: Servers crashing, can't create new servers
**Solution**:
```bash
# Check memory usage
free -h
docker system df

# Clean up Docker
docker system prune -a

# Add swap if needed
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

#### Terraform Won't Add New Node
**Error**: "Error: creating instance: error creating server: ..."
**Solutions**:
```bash
# 1. Check provider quotas/limits
# Vultr: Check account limits
# DO: Check droplet limit

# 2. Try different region
# In terraform.tfvars, change region

# 3. Manually import existing resource
terraform import module.wings["west"].vultr_instance.wings <instance-id>
```

### Recovery Procedures

#### Restore Panel from Backup
```bash
# Restore database
mysql -u root -p panel < backup.sql

# Restore files
cd /var/www
tar -xzf pterodactyl-backup.tar.gz

# Fix permissions
chown -R www-data:www-data pterodactyl
chmod -R 755 pterodactyl/storage
chmod -R 755 pterodactyl/bootstrap/cache

# Clear cache
cd pterodactyl
php artisan cache:clear
```

#### Recreate Wings Node
```bash
# In Terraform
terraform destroy -target=module.wings["node-name"]
terraform apply -target=module.wings["node-name"]

# Reconfigure in Panel
# Nodes → Create New → Configure
```

#### Emergency Server Access
```bash
# If panel is down but Wings running
# Direct Docker access on Wings node
docker ps  # Find container
docker exec -it <container-id> bash
# Can manage server directly
```

## Getting Help

### Collect Diagnostics
```bash
# Create diagnostic bundle
mkdir mgetf-diagnostics
cd mgetf-diagnostics

# Terraform state
terraform show > terraform-state.txt

# Panel logs
ssh root@panel-ip "journalctl -u nginx -n 100" > panel-nginx.log
ssh root@panel-ip "tail -n 100 /var/www/pterodactyl/storage/logs/laravel-*.log" > panel-laravel.log

# Wings logs
ssh root@wings-ip "journalctl -u wings -n 100" > wings.log
ssh root@wings-ip "docker ps -a" > docker-ps.log

# Network info
ssh root@wings-ip "netstat -tulpn" > network.log

# Compress
tar -czf diagnostics.tar.gz *
```

### Where to Get Help
1. **Discord**: mge.tf dev channel (fastest)
2. **GitHub Issues**: For bugs/features
3. **Email**: admin@mge.tf
4. **Pterodactyl Discord**: For panel-specific issues
5. **SourceMod Forums**: For plugin issues

### Useful Commands Reference
```bash
# Terraform
terraform state list              # List all resources
terraform state show <resource>   # Show resource details
terraform taint <resource>        # Mark for recreation
terraform console                 # Interactive console

# Panel
php artisan list                  # All artisan commands
php artisan queue:work            # Process queued jobs
php artisan schedule:run          # Run scheduled tasks

# Wings  
wings diagnostics                 # System diagnostics
wings configure --panel-url <url> --token <token>  # Reconfigure

# Docker
docker system df                  # Disk usage
docker logs --tail 50 -f <id>    # Live logs
docker exec -it <id> bash        # Shell access
```