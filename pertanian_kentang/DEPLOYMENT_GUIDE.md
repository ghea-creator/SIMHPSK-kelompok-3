# SIMHPSK - Deployment Guide

Panduan lengkap untuk deployment SIMHPSK ke server production.

## Prerequisites

- PHP 8.2+
- MySQL 5.7+ (atau MariaDB 10.3+)
- Composer
- Git (opsional)
- SSL Certificate (HTTPS)
- Web Server (Nginx atau Apache)

## 1. Server Preparation

### 1.1 Update Server
```bash
sudo apt update && sudo apt upgrade -y
```

### 1.2 Install Dependencies
```bash
# Nginx
sudo apt install -y nginx

# PHP 8.2
sudo apt install -y php8.2-fpm php8.2-cli php8.2-mysql php8.2-mbstring php8.2-xml php8.2-bcmath php8.2-curl php8.2-zip php8.2-gd php8.2-json

# MySQL
sudo apt install -y mysql-server mysql-client

# Tools
sudo apt install -y git composer curl wget
```

### 1.3 Create Database & User
```bash
mysql -u root -p

CREATE DATABASE simhpsk;
CREATE USER 'simhpsk_user'@'localhost' IDENTIFIED BY 'strong_password_here';
GRANT ALL PRIVILEGES ON simhpsk.* TO 'simhpsk_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

## 2. Application Deployment

### 2.1 Clone Repository
```bash
cd /var/www
sudo git clone https://github.com/your-repo/pertanian_kentang.git simhpsk
cd simhpsk
```

### 2.2 Set Permissions
```bash
sudo chown -R www-data:www-data /var/www/simhpsk
sudo chmod -R 755 /var/www/simhpsk
sudo chmod -R 775 /var/www/simhpsk/storage
sudo chmod -R 775 /var/www/simhpsk/bootstrap/cache
```

### 2.3 Install Composer Dependencies
```bash
composer install --no-dev --optimize-autoloader
```

### 2.4 Environment Configuration
```bash
cp .env.example .env

# Edit .env dengan production values
nano .env
```

**Production .env Settings:**
```
APP_ENV=production
APP_DEBUG=false
APP_KEY=base64:your_generated_key_here

DB_HOST=localhost
DB_DATABASE=simhpsk
DB_USERNAME=simhpsk_user
DB_PASSWORD=strong_password_here

MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=your-email@gmail.com
MAIL_FROM_NAME="${APP_NAME}"
```

### 2.5 Generate App Key
```bash
php artisan key:generate
```

### 2.6 Run Migrations
```bash
php artisan migrate --force
```

### 2.7 Seed Database (Optional)
```bash
php artisan db:seed --force
```

### 2.8 Optimize Application
```bash
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan optimize
```

## 3. Web Server Configuration

### 3.1 Nginx Configuration

Create `/etc/nginx/sites-available/simhpsk`:

```nginx
server {
    listen 80;
    server_name simhpsk.com www.simhpsk.com;

    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name simhpsk.com www.simhpsk.com;

    # SSL Certificate
    ssl_certificate /etc/letsencrypt/live/simhpsk.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/simhpsk.com/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    root /var/www/simhpsk/public;
    index index.php;

    # Logging
    access_log /var/log/nginx/simhpsk_access.log;
    error_log /var/log/nginx/simhpsk_error.log;

    # Max upload size
    client_max_body_size 50M;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    location ~ /\.ht {
        deny all;
    }

    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

Enable site:
```bash
sudo ln -s /etc/nginx/sites-available/simhpsk /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 3.2 Apache Configuration

Create `/etc/apache2/sites-available/simhpsk.conf`:

```apache
<VirtualHost *:80>
    ServerName simhpsk.com
    ServerAlias www.simhpsk.com
    Redirect permanent / https://simhpsk.com/
</VirtualHost>

<VirtualHost *:443>
    ServerName simhpsk.com
    ServerAlias www.simhpsk.com

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/simhpsk.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/simhpsk.com/privkey.pem

    DocumentRoot /var/www/simhpsk/public

    <Directory /var/www/simhpsk/public>
        AllowOverride All
        Require all granted
        
        <IfModule mod_rewrite.c>
            RewriteEngine On
            RewriteBase /
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteCond %{REQUEST_FILENAME} !-d
            RewriteRule . /index.php [L]
        </IfModule>
    </Directory>

    LogFormat combined
    CustomLog /var/log/apache2/simhpsk_access.log combined
    ErrorLog /var/log/apache2/simhpsk_error.log
</VirtualHost>
```

Enable site:
```bash
sudo a2enmod rewrite
sudo a2enmod ssl
sudo a2ensite simhpsk.conf
sudo systemctl restart apache2
```

## 4. SSL Certificate

### Using Let's Encrypt (Recommended)

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot certonly --nginx -d simhpsk.com -d www.simhpsk.com

# Auto renewal
sudo certbot renew --dry-run
```

## 5. Database Backup

### Automated Daily Backup
```bash
# Create backup script: /usr/local/bin/backup-simhpsk.sh
#!/bin/bash
BACKUP_DIR="/var/backups/simhpsk"
mkdir -p $BACKUP_DIR
mysqldump -u simhpsk_user -p'strong_password' simhpsk | gzip > "$BACKUP_DIR/simhpsk_$(date +%Y%m%d_%H%M%S).sql.gz"

# Keep only last 7 days
find $BACKUP_DIR -name "*.gz" -mtime +7 -delete
```

Add to crontab:
```bash
sudo crontab -e
# Add: 0 2 * * * /usr/local/bin/backup-simhpsk.sh
```

## 6. Monitoring & Logging

### Application Logs
```bash
# Real-time logs
tail -f /var/www/simhpsk/storage/logs/laravel.log

# Error monitoring
tail -f /var/log/nginx/simhpsk_error.log
```

### System Monitoring
```bash
# Check disk space
df -h

# Check memory
free -h

# Check CPU
top
```

## 7. Performance Optimization

### 7.1 PHP-FPM Tuning
Edit `/etc/php/8.2/fpm/pool.d/www.conf`:

```ini
pm = dynamic
pm.max_children = 50
pm.start_servers = 20
pm.min_spare_servers = 10
pm.max_spare_servers = 30
pm.max_requests = 500
```

Restart:
```bash
sudo systemctl restart php8.2-fpm
```

### 7.2 MySQL Optimization
Edit `/etc/mysql/mysql.conf.d/mysqld.cnf`:

```ini
max_connections = 200
innodb_buffer_pool_size = 1G
query_cache_type = 1
query_cache_size = 64M
```

Restart:
```bash
sudo systemctl restart mysql
```

### 7.3 Nginx Caching
Already configured in nginx config above for static assets.

## 8. Security Hardening

### 8.1 Firewall
```bash
sudo ufw enable
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### 8.2 Fail2Ban
```bash
sudo apt install fail2ban

# Create /etc/fail2ban/jail.local
[sshd]
enabled = true
maxretry = 5

sudo systemctl restart fail2ban
```

### 8.3 File Permissions
```bash
# Restrict .env file
chmod 600 /var/www/simhpsk/.env

# Restrict config files
chmod 644 /var/www/simhpsk/config/*
```

## 9. Deployment Commands (Quick Reference)

```bash
cd /var/www/simhpsk

# Pull latest code
git pull origin main

# Install/update dependencies
composer install --no-dev --optimize-autoloader

# Run migrations
php artisan migrate --force

# Cache configuration
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Clear old cache if needed
php artisan cache:clear
php artisan view:clear
```

## 10. Monitoring Checklist

- [ ] Check application logs regularly
- [ ] Monitor disk space (should have >10% free)
- [ ] Monitor MySQL performance
- [ ] Check SSL certificate expiration date
- [ ] Verify database backups are running
- [ ] Monitor server resource usage
- [ ] Check for security updates
- [ ] Test failover procedures

## 11. Troubleshooting

### 502 Bad Gateway
```bash
# Check PHP-FPM status
systemctl status php8.2-fpm

# Check Nginx error log
tail -f /var/log/nginx/error.log
```

### Permission Denied
```bash
# Fix ownership
sudo chown -R www-data:www-data /var/www/simhpsk

# Fix permissions
sudo chmod -R 755 /var/www/simhpsk
sudo chmod -R 775 /var/www/simhpsk/storage bootstrap/cache
```

### Database Connection Error
```bash
# Check MySQL
systemctl status mysql

# Test connection
mysql -u simhpsk_user -p -h localhost simhpsk -e "SELECT 1;"
```

### High Memory Usage
```bash
# Check running processes
ps aux --sort=-%mem | head -20

# Increase PHP memory limit in php.ini
memory_limit = 512M
```

## 12. Rollback Procedure

If deployment fails:

```bash
cd /var/www/simhpsk

# Revert to previous code
git revert HEAD --no-edit

# Clear cache
php artisan cache:clear
php artisan view:clear

# Restart services
sudo systemctl restart php8.2-fpm nginx
```

## Support

Untuk masalah deployment, hubungi DevOps team atau check logs lebih detail.
