# ============================================================
# DOCKER_PRODUCTION_GUIDE.md
# Panduan Deploy Laravel Backend ke VPS menggunakan Docker
# ============================================================

# 🐳 Panduan Deploy ke VPS (Docker Production)

## Struktur File Docker

```
pertanian_kentang/
├── Dockerfile                    ← Multi-stage build image
├── docker-compose.yml            ← Orchestration services
├── .env.production               ← Template environment (template saja, isi sendiri)
└── docker/
    ├── entrypoint.sh             ← Startup script otomatis
    ├── nginx/conf.d/default.conf ← Konfigurasi Nginx
    ├── php/
    │   ├── php-fpm.conf          ← PHP-FPM pool config
    │   └── php.ini               ← PHP production settings
    ├── mysql/init.sql            ← Inisialisasi database
    └── supervisor/supervisord.conf ← Process manager
```

## Arsitektur

```
Flutter App (Mobile/Web)
        │
        │ HTTPS
        ▼
    [VPS Server]
    ┌─────────────────────────────────┐
    │  Docker Container: app          │
    │  ┌──────────┐ ┌──────────────┐ │
    │  │  Nginx   │ │  PHP-FPM     │ │
    │  │ (Port 80)│ │ (Unix Socket)│ │
    │  └──────────┘ └──────────────┘ │
    │  ┌────────────┐ ┌───────────┐  │
    │  │Queue Worker│ │ Scheduler │  │
    │  └────────────┘ └───────────┘  │
    └─────────────────────────────────┘
              │              │
    ┌─────────┘    ┌─────────┘
    ▼              ▼
[MySQL 8.0]   [Redis 7]
(kentang_db)  (kentang_cache)
```

---

## 🚀 Cara Deploy ke VPS

### Langkah 1: Persiapan VPS

```bash
# Update sistem
sudo apt update && sudo apt upgrade -y

# Install Docker & Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt install docker-compose-plugin -y

# Tambahkan user ke group docker
sudo usermod -aG docker $USER
newgrp docker
```

### Langkah 2: Upload Project ke VPS

```bash
# Dari komputer lokal Anda (Windows PowerShell):
# Pilih salah satu cara:

# Cara A: Git clone
git clone https://github.com/USERNAME/pertanian_kentang.git
cd pertanian_kentang

# Cara B: SCP (upload langsung)
scp -r C:/laragon/www/pertanian_kentang user@IP_VPS:/home/user/
```

### Langkah 3: Setup Environment

```bash
# Di VPS, masuk ke folder project
cd /home/user/pertanian_kentang

# Buat file .env dari template
cp .env.production .env

# Edit .env – ISI nilai yang bertanda "WAJIB DIGANTI"
nano .env
```

**Nilai yang WAJIB diisi di .env:**
| Key | Contoh Nilai |
|-----|-------------|
| `APP_KEY` | Jalankan: `docker run --rm php:8.3-cli php -r "echo 'base64:'.base64_encode(random_bytes(32));"` |
| `APP_URL` | `http://IP_VPS_ANDA` atau `https://api.domain.com` |
| `DB_PASSWORD` | Password kuat, minimal 16 karakter |
| `DB_ROOT_PASSWORD` | Password kuat berbeda dari DB_PASSWORD |
| `REDIS_PASSWORD` | Password kuat |

### Langkah 4: Build dan Jalankan

```bash
# Build image (pertama kali ~5-10 menit)
docker compose build

# Jalankan semua services di background
docker compose up -d

# Lihat log startup
docker compose logs -f app
```

### Langkah 5: Verifikasi

```bash
# Cek status semua container
docker compose ps

# Cek health app
curl http://localhost/health

# Cek API berjalan
curl http://localhost/api/health

# Masuk ke container app
docker compose exec app bash
```

---

## 🔧 Perintah Berguna

```bash
# Restart semua service
docker compose restart

# Restart hanya app
docker compose restart app

# Lihat log real-time
docker compose logs -f app

# Jalankan artisan command
docker compose exec app php artisan migrate
docker compose exec app php artisan cache:clear
docker compose exec app php artisan queue:restart

# Backup database
docker compose exec db mysqldump -u root -p pertanian_kentang > backup.sql

# Update aplikasi (saat ada kode baru)
git pull
docker compose build app
docker compose up -d --no-deps app
```

---

## 🔒 Keamanan Tambahan (Rekomendasi)

### 1. HTTPS dengan SSL (Let's Encrypt)
```bash
# Install Certbot
sudo apt install certbot

# Generate certificate
sudo certbot certonly --standalone -d api.domainanda.com

# Copy ke folder docker
sudo cp /etc/letsencrypt/live/api.domainanda.com/fullchain.pem docker/ssl/
sudo cp /etc/letsencrypt/live/api.domainanda.com/privkey.pem docker/ssl/
```

Lalu uncomment baris SSL di `docker-compose.yml` dan tambahkan konfigurasi HTTPS di `default.conf`.

### 2. Firewall
```bash
# Hanya buka port yang diperlukan
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP
sudo ufw allow 443   # HTTPS
sudo ufw enable
```

### 3. Update Flutter App
Setelah backend berjalan di VPS, update URL di Flutter app:
```dart
// lib/services/api_service.dart
static const String baseUrl = 'http://IP_VPS_ANDA';
// atau jika sudah ada domain:
static const String baseUrl = 'https://api.domainanda.com';
```

---

## ⚠️ Checklist Sebelum Production

- [ ] `APP_KEY` sudah diisi (bukan nilai default)
- [ ] `APP_DEBUG=false`
- [ ] Semua password database kuat dan unik
- [ ] Port MySQL & Redis **tidak** di-expose ke luar
- [ ] Firewall sudah dikonfigurasi
- [ ] Storage & logs menggunakan Docker volumes
- [ ] Health check berjalan: `curl http://VPS_IP/health`
- [ ] API bisa diakses: `curl http://VPS_IP/api/health`
