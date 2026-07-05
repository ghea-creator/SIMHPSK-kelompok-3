# Quick Start - Backend Pertanian Kentang API

## 🚀 Start in 5 Minutes

### Prerequisites
- Docker & Docker Compose installed
- OR PHP 8.3, Composer, PostgreSQL/MySQL locally

---

## Option 1: Docker (Recommended)

### 1. Start Services
```bash
cd pertanian_kentang
docker-compose up --build
```

### 2. Run Migrations
```bash
docker-compose exec app php artisan migrate --force
```

### 3. Test API
```bash
curl http://localhost:8000/api/seasons
# Returns: {"success":false,"message":"Unauthorized"} ← Expected (needs token)
```

### 4. Done! 🎉
- API running: `http://localhost:8000/api`
- PostgreSQL: `localhost:5432`
- Redis cache: `localhost:6379`

---

## Option 2: Local Development (Laragon)

### 1. Setup
```bash
cd c:\laragon\www\pertanian_kentang
composer install
php artisan key:generate
```

### 2. Configure `.env`
```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_DATABASE=web_kentang
DB_USERNAME=root
```

### 3. Migrate Database
```bash
php artisan migrate
```

### 4. Start Server
```bash
php artisan serve
# API: http://localhost:8000/api
```

---

## 📱 Testing API Endpoints

### 1. Register User
```bash
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "farm_name": "Kebun Kentang",
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "081234567890",
    "password": "password123",
    "password_confirmation": "password123"
  }'
```

### 2. Login
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123"
  }'

# Response contains: "token": "1|abc123..."
```

### 3. Use Token (Copy token from login response)
```bash
TOKEN="1|abc123..."

# Get seasons
curl -X GET http://localhost:8000/api/seasons \
  -H "Authorization: Bearer $TOKEN"

# Create season
curl -X POST http://localhost:8000/api/seasons \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "Spring 2026",
    "start_date": "2026-03-01",
    "end_date": "2026-05-31",
    "status": "active",
    "target_kg": 5000
  }'
```

---

## 🔑 Key Endpoints

### Authentication
```
POST   /api/auth/register       - Register
POST   /api/auth/login          - Login (get token)
POST   /api/auth/logout         - Logout
GET    /api/auth/me             - Current user
```

### Main Resources
```
GET    /api/seasons             - List seasons
POST   /api/seasons             - Create season
GET    /api/seasons/{id}        - View season
PUT    /api/seasons/{id}        - Update season
DELETE /api/seasons/{id}        - Delete season

GET    /api/harvests            - List harvests
POST   /api/harvests            - Record harvest
GET    /api/harvests/{id}       - View harvest
PUT    /api/harvests/{id}       - Update harvest
DELETE /api/harvests/{id}       - Delete harvest

GET    /api/sales               - List sales
POST   /api/sales               - Create sale
GET    /api/sales/{id}          - View sale
PUT    /api/sales/{id}          - Update sale
DELETE /api/sales/{id}          - Delete sale

GET    /api/costs               - List costs
POST   /api/costs               - Record cost
GET    /api/costs/{id}          - View cost
PUT    /api/costs/{id}          - Update cost
DELETE /api/costs/{id}          - Delete cost
```

### Stock & Reports
```
GET    /api/stock               - Stock status
POST   /api/stock/in            - Add incoming stock
POST   /api/stock/out           - Add outgoing stock

GET    /api/dashboard           - Dashboard data
GET    /api/reports/profit-loss - Profit/Loss report
GET    /api/reports/target-vs-actual - Target vs Actual
```

### User Settings
```
GET    /api/settings            - Get settings
POST   /api/settings/profile    - Update profile
POST   /api/settings/password   - Change password
POST   /api/settings/gudang     - Update warehouse settings
```

---

## 🐳 Docker Commands

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f app

# Run artisan command
docker-compose exec app php artisan migrate

# Access database
docker-compose exec db psql -U postgres -d pertanian_kentang

# Stop services
docker-compose down

# Restart specific service
docker-compose restart app
```

---

## 📝 Response Format

### Success (200, 201)
```json
{
  "success": true,
  "message": "Operation successful",
  "data": {
    "id": 1,
    "name": "Spring 2026",
    "start_date": "2026-03-01",
    "end_date": "2026-05-31",
    "status": "active",
    "target_kg": 5000,
    "created_at": "2026-05-17T10:00:00.000000Z"
  }
}
```

### Error (4xx, 5xx)
```json
{
  "success": false,
  "message": "Resource not found",
  "data": null
}
```

### Validation Error (422)
```json
{
  "success": false,
  "message": "Validation error",
  "errors": {
    "name": ["The name field is required"],
    "email": ["The email must be valid"]
  }
}
```

---

## 🔐 Authentication Header

All authenticated endpoints require:
```
Authorization: Bearer {token}
```

Example:
```bash
curl -H "Authorization: Bearer 1|abc123def456..."
```

---

## 💾 Database

### PostgreSQL (Docker)
```
Host: localhost (from host machine)
Host: db (from containers)
Port: 5432
Database: pertanian_kentang
User: postgres
Password: postgres_password_123
```

### Backup Database
```bash
docker-compose exec db pg_dump -U postgres pertanian_kentang > backup.sql
```

### Restore Database
```bash
docker-compose exec db psql -U postgres pertanian_kentang < backup.sql
```

---

## 📚 Full Documentation

- **API Details**: See [API_GUIDE.md](API_GUIDE.md)
- **Deployment**: See [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md)
- **Transformation**: See [BACKEND_TRANSFORMATION.md](BACKEND_TRANSFORMATION.md)

---

## ⚠️ Common Issues

### Port already in use
```bash
# Change port in docker-compose.yml
# Or stop other services using these ports
lsof -i :8000  # Find what's using port 8000
```

### Database connection error
```bash
# Verify container is running
docker-compose ps

# Check logs
docker-compose logs db
```

### API returns 500 error
```bash
# Check application logs
docker-compose logs app

# Clear cache
docker-compose exec app php artisan cache:clear
```

### Can't connect to database
```bash
# Make sure migrations ran
docker-compose exec app php artisan migrate

# Test connection
docker-compose exec db psql -U postgres -c "SELECT 1"
```

---

## 🎯 Next Steps

1. **Read API Documentation**: [API_GUIDE.md](API_GUIDE.md)
2. **Setup Production**: [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md)
3. **Develop Flutter App**: Use API endpoints from above
4. **Deploy to Cloud**: Follow deployment guide

---

## 💬 Support

For issues or questions:
1. Check the full documentation files
2. Review error logs: `docker-compose logs app`
3. Verify database: `docker-compose exec db psql -U postgres`
4. Contact development team

---

**Happy Coding! 🚀**
