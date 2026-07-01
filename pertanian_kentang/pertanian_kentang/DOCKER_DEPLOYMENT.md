# DOCKER DEPLOYMENT GUIDE - Pertanian Kentang

## Prerequisites

- Docker Desktop (Windows/Mac) atau Docker Engine (Linux)
- Docker Compose
- Minimal 4GB RAM available untuk containers
- Port 80, 443, 8000, 5432, 6379 harus tersedia

---

## 1. Quick Start

### Clone Repository
```bash
cd /path/to/projects
git clone <repository-url>
cd pertanian_kentang
```

### Setup Environment
```bash
# Copy .env.docker ke .env
cp .env.docker .env

# Generate APP_KEY jika belum ada
php artisan key:generate

# Atau set manual:
# APP_KEY=base64:YOUR_KEY_HERE
```

### Build & Start Containers
```bash
# Build images dan start services
docker-compose up --build

# Or run in background
docker-compose up -d --build

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Initialize Database
```bash
# Run migrations
docker-compose exec app php artisan migrate --force

# (Optional) Seed database
docker-compose exec app php artisan db:seed

# (Optional) Create admin user
docker-compose exec app php artisan tinker
# Ketik: User::create(['name' => 'Admin', 'email' => 'admin@localhost', 'password' => Hash::make('password'), 'role' => 'super_admin', 'status' => 'active', 'approval' => 'approved'])
```

### Access Application
- **API**: http://localhost:8000/api
- **Database**: localhost:5432 (PostgreSQL)
- **Redis Cache**: localhost:6379
- **Nginx**: http://localhost (port 80)

---

## 2. Docker Services

### app (Laravel Application)
- PHP 8.3 FPM
- Runs on container port 9000
- Mounts current directory as volume
- Auto-runs migrations on startup

### db (PostgreSQL)
- PostgreSQL 16
- Port: 5432
- Database: `pertanian_kentang`
- Username: `postgres`
- Password: `postgres_password_123`
- Persistent storage in `db_data` volume

### cache (Redis)
- Redis 7
- Port: 6379
- Used for caching & sessions
- Persistent storage in `cache_data` volume

### nginx (Web Server)
- Nginx Alpine
- Ports: 80 (HTTP), 443 (HTTPS)
- Proxies requests to PHP-FPM
- Static file serving
- Gzip compression enabled

### scheduler (Background Jobs)
- Runs Laravel scheduled tasks
- Executes every minute
- Optional service

---

## 3. Useful Commands

### Database Management
```bash
# Connect to PostgreSQL
docker-compose exec db psql -U postgres -d pertanian_kentang

# Backup database
docker-compose exec db pg_dump -U postgres pertanian_kentang > backup.sql

# Restore database
docker-compose exec db psql -U postgres pertanian_kentang < backup.sql

# Run fresh migrations
docker-compose exec app php artisan migrate:fresh --force

# Seed database
docker-compose exec app php artisan db:seed
```

### Application Management
```bash
# Run artisan commands
docker-compose exec app php artisan <command>

# Clear cache
docker-compose exec app php artisan cache:clear

# Clear all caches
docker-compose exec app php artisan optimize:clear

# Run tinker (interactive shell)
docker-compose exec app php artisan tinker

# Run tests
docker-compose exec app php artisan test

# Regenerate autoload
docker-compose exec app composer dump-autoload
```

### Logs & Debugging
```bash
# View app logs
docker-compose logs -f app

# View specific lines
docker-compose logs --tail=50 app

# View all services logs
docker-compose logs -f

# View logs timestamped
docker-compose logs --timestamps -f app
```

### Container Management
```bash
# List running containers
docker-compose ps

# Stop all services
docker-compose stop

# Stop specific service
docker-compose stop app

# Start services
docker-compose start

# Restart services
docker-compose restart app

# Remove all containers (keeps data volumes)
docker-compose down

# Remove containers & volumes (DESTRUCTIVE)
docker-compose down -v

# View container details
docker inspect <container-id>
```

---

## 4. API Testing

### Login & Get Token
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@localhost",
    "password": "password"
  }'
```

### Use Token for Requests
```bash
curl -X GET http://localhost:8000/api/seasons \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## 5. Production Deployment

### Before Deploying

1. **Update .env**
   ```bash
   APP_ENV=production
   APP_DEBUG=false
   APP_URL=https://yourdomain.com
   
   DB_HOST=your-db-host
   DB_DATABASE=prod_database
   DB_USERNAME=prod_user
   DB_PASSWORD=strong_password_here
   
   REDIS_HOST=your-redis-host
   
   SANCTUM_STATEFUL_DOMAINS=yourdomain.com
   ```

2. **Update docker-compose.yml**
   - Change port mappings for security
   - Set resource limits
   - Update environment variables
   - Configure SSL certificates

3. **Build Production Image**
   ```bash
   docker build --target production -t pertanian-kentang:1.0 .
   ```

4. **Push to Registry**
   ```bash
   # Docker Hub
   docker tag pertanian-kentang:1.0 yourrepo/pertanian-kentang:1.0
   docker push yourrepo/pertanian-kentang:1.0
   
   # Private Registry
   docker tag pertanian-kentang:1.0 registry.company.com/pertanian-kentang:1.0
   docker push registry.company.com/pertanian-kentang:1.0
   ```

### Deploy on Server

```bash
# SSH to server
ssh user@yourserver

# Clone/pull repository
cd /apps
git clone <repo> pertanian_kentang
cd pertanian_kentang

# Copy production .env
cp .env.production .env

# Pull latest images
docker-compose pull

# Start services
docker-compose up -d

# Run migrations
docker-compose exec app php artisan migrate --force

# View logs
docker-compose logs -f app
```

---

## 6. Scaling & Performance

### Increase Resource Limits
Edit `docker-compose.yml`:
```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

### Load Balancing (Multiple App Instances)
```yaml
# docker-compose.yml
services:
  app:
    deploy:
      replicas: 3  # Run 3 instances
```

### Database Optimization
```bash
# Connect to DB
docker-compose exec db psql -U postgres -d pertanian_kentang

# Analyze query performance
EXPLAIN ANALYZE SELECT * FROM harvests WHERE user_id = 1;

# Create indexes
CREATE INDEX idx_harvests_user_id ON harvests(user_id);
```

---

## 7. Monitoring & Maintenance

### Check Container Health
```bash
docker-compose exec app php artisan tinker
# Check: DB::connection()->getPdo() or die("DB failed");
```

### Monitor Resource Usage
```bash
docker stats

# Output:
# CONTAINER          CPU %     MEM USAGE / LIMIT     MEM %
# app                0.15%     150MiB / 2GiB         7.5%
# db                 0.08%     200MiB / 2GiB         10%
```

### Automated Backups
```bash
# Create backup script
cat > backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
docker-compose exec -T db pg_dump -U postgres pertanian_kentang | gzip > "backup_$DATE.sql.gz"
echo "Backup created: backup_$DATE.sql.gz"
EOF

chmod +x backup.sh

# Schedule with cron (every day at 2 AM)
# 0 2 * * * cd /apps/pertanian_kentang && ./backup.sh
```

---

## 8. Troubleshooting

### Container won't start
```bash
# Check logs
docker-compose logs app

# Common issues:
# - Port already in use: Change port in docker-compose.yml
# - Permission denied: Check file ownership
# - Out of memory: Increase Docker memory allocation
```

### Database connection error
```bash
# Verify DB is running
docker-compose ps db

# Check DB logs
docker-compose logs db

# Test connection
docker-compose exec db psql -U postgres -c "SELECT 1"
```

### API returns 500 error
```bash
# Check application logs
docker-compose logs app

# Clear cache
docker-compose exec app php artisan cache:clear

# Run migrations
docker-compose exec app php artisan migrate
```

### Nginx/404 errors
```bash
# Verify app is running
docker-compose exec app curl http://localhost:9000/api/seasons

# Check nginx config
docker-compose exec nginx nginx -t

# Restart nginx
docker-compose restart nginx
```

### Redis connection error
```bash
# Check redis is running
docker-compose ps cache

# Test redis connection
docker-compose exec cache redis-cli ping

# View redis keys
docker-compose exec cache redis-cli KEYS "*"
```

---

## 9. Security Best Practices

### Update passwords
- Change `postgres_password_123` to a strong password
- Update `APP_KEY` with a generated secure key

### Enable SSL/TLS
```bash
# Update docker-compose.yml for SSL
# Configure nginx SSL certificate paths
```

### Network Isolation
```yaml
# Create separate network for db
networks:
  frontend:
  backend:

# Only expose frontend services
```

### Environment Variables
- Never commit `.env` to version control
- Use separate `.env.docker`, `.env.production`
- Rotate API keys regularly

---

## 10. CI/CD Integration

### GitHub Actions Example
```yaml
name: Deploy to Docker

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build Docker image
        run: docker build -t pertanian-kentang:latest .
      - name: Push to registry
        run: docker push pertanian-kentang:latest
      - name: Deploy
        run: ssh deploy@server 'cd /apps && docker-compose pull && docker-compose up -d'
```

---

## Support

Untuk masalah atau pertanyaan, hubungi tim development.
