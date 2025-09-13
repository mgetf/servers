#!/bin/bash
set -euo pipefail

# Update system
apt-get update && apt-get upgrade -y

# Install dependencies
apt-get install -y software-properties-common curl apt-transport-https ca-certificates gnupg lsb-release

# Add PHP repository
add-apt-repository -y ppa:ondrej/php
apt-get update

# Install PHP and extensions
apt-get install -y php8.2 php8.2-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip}

# Install MariaDB (if local database)
if [[ "${DB_PROVIDER:-local}" == "local" ]]; then
    apt-get install -y mariadb-server
    systemctl enable --now mariadb
    
    # Secure MariaDB installation
    mysql -e "UPDATE mysql.user SET Password=PASSWORD('panel_secure_pass') WHERE User='root';"
    mysql -e "DELETE FROM mysql.user WHERE User='';"
    mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    mysql -e "DROP DATABASE IF EXISTS test;"
    mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
    mysql -e "FLUSH PRIVILEGES;"
    
    # Create panel database
    mysql -e "CREATE DATABASE IF NOT EXISTS panel;"
    mysql -e "CREATE USER IF NOT EXISTS 'pterodactyl'@'127.0.0.1' IDENTIFIED BY 'panel_db_pass';"
    mysql -e "GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1';"
    mysql -e "FLUSH PRIVILEGES;"
fi

# Install Redis
apt-get install -y redis-server
systemctl enable --now redis-server

# Install Nginx
apt-get install -y nginx
systemctl enable --now nginx

# Install Composer
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install Certbot for SSL
apt-get install -y certbot python3-certbot-nginx

# Create pterodactyl directory
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl

# Download Pterodactyl Panel
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/

# Install PHP dependencies
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader

# Generate application key
php artisan key:generate --force

# Copy environment file
cp .env.example .env

echo "Panel base installation complete"