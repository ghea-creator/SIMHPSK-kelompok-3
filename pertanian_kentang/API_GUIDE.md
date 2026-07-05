# API Documentation - Pertanian Kentang

## Overview

Backend sistem Pertanian Kentang telah direfactor menjadi **RESTful API** yang sepenuhnya API-driven. Backend ini menyediakan endpoint JSON API yang dapat dikonsumsi oleh aplikasi mobile Flutter atau frontend lainnya.

## Base URL

- **Local Development**: `http://localhost:8000/api`
- **Docker Container**: `http://localhost:8000/api`
- **Production**: `https://your-domain.com/api`

## Authentication

API menggunakan **Laravel Sanctum** untuk autentikasi token-based. Setiap request (kecuali login/register) harus menyertakan token.

### Format Header

```
Authorization: Bearer {token}
Content-Type: application/json
```

### Mendapatkan Token

**Endpoint**: `POST /api/auth/register`
```json
{
  "farm_name": "Kebun Kentang Saya",
  "name": "Nama Pemilik",
  "email": "user@example.com",
  "phone": "081234567890",
  "password": "password123",
  "password_confirmation": "password123"
}
```

**Response Success (201)**:
```json
{
  "success": true,
  "message": "Pendaftaran berhasil! Tunggu persetujuan admin.",
  "data": {
    "id": 1,
    "email": "user@example.com",
    "name": "Nama Pemilik",
    "farm_name": "Kebun Kentang Saya",
    "status": "pending_approval"
  }
}
```

### Login

**Endpoint**: `POST /api/auth/login`
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response Success (200)**:
```json
{
  "success": true,
  "message": "Login berhasil.",
  "data": {
    "token": "1|abc123def456ghi789...",
    "token_type": "Bearer",
    "user": {
      "id": 1,
      "name": "Nama Pemilik",
      "email": "user@example.com",
      "farm_name": "Kebun Kentang Saya",
      "phone": "081234567890",
      "role": "user",
      "status": "active",
      "approval": "approved"
    }
  }
}
```

### Logout

**Endpoint**: `POST /api/auth/logout`

**Header**:
```
Authorization: Bearer {token}
```

**Response Success (200)**:
```json
{
  "success": true,
  "message": "Logout berhasil.",
  "data": null
}
```

### Get Current User

**Endpoint**: `GET /api/auth/me`

**Header**:
```
Authorization: Bearer {token}
```

**Response Success (200)**:
```json
{
  "success": true,
  "message": "Success.",
  "data": {
    "id": 1,
    "name": "Nama Pemilik",
    "email": "user@example.com",
    "farm_name": "Kebun Kentang Saya",
    "phone": "081234567890",
    "role": "user",
    "status": "active",
    "approval": "approved",
    "created_at": "2026-05-17T10:00:00.000000Z",
    "updated_at": "2026-05-17T10:00:00.000000Z"
  }
}
```

---

## API Endpoints

### 1. Dashboard

**GET** `/api/dashboard` - Get dashboard summary
- Returns: Dashboard statistics

### 2. Seasons (Musim Tanam)

**GET** `/api/seasons` - List all seasons
- Query Params: `per_page=15`
- Returns: Array of seasons with pagination

**POST** `/api/seasons` - Create new season
```json
{
  "name": "Musim Tanam 2026",
  "start_date": "2026-05-01",
  "end_date": "2026-08-31",
  "status": "active",
  "target_kg": 5000
}
```

**GET** `/api/seasons/{id}` - Get single season
- Returns: Season details

**PUT** `/api/seasons/{id}` - Update season
```json
{
  "name": "Musim Tanam 2026 - Updated",
  "start_date": "2026-05-01",
  "end_date": "2026-08-31",
  "status": "active",
  "target_kg": 6000
}
```

**DELETE** `/api/seasons/{id}` - Delete season
- Returns: Success message

### 3. Harvests (Pencatatan Panen)

**GET** `/api/harvests` - List all harvests
- Query Params: 
  - `per_page=15`
  - `season_id=1` (optional filter)
- Returns: Harvests with pagination, active season, total harvest

**POST** `/api/harvests` - Record new harvest
```json
{
  "season_id": 1,
  "date": "2026-06-15",
  "weight_kg": 250.5,
  "notes": "Panen hari ini",
  "photo": "base64_encoded_image_or_file"
}
```

**GET** `/api/harvests/{id}` - Get single harvest

**PUT** `/api/harvests/{id}` - Update harvest record
```json
{
  "season_id": 1,
  "date": "2026-06-15",
  "weight_kg": 260,
  "status": "verified",
  "notes": "Updated notes",
  "photo": "base64_encoded_image_or_file"
}
```

**DELETE** `/api/harvests/{id}` - Delete harvest

### 4. Stock (Persediaan Barang)

**GET** `/api/stock` - Get stock status
- Query Params: `per_page=15`
- Returns: Current balance, min/max stock, status, transactions

**POST** `/api/stock/in` - Record incoming stock
```json
{
  "amount": 100.5,
  "notes": "Stock masuk dari supplier"
}
```

**POST** `/api/stock/out` - Record outgoing stock
```json
{
  "amount": 50.25,
  "notes": "Stock keluar dijual"
}
```

**DELETE** `/api/stock/{transaction_id}` - Delete stock transaction

### 5. Sales (Penjualan)

**GET** `/api/sales` - List all sales
- Query Params: `per_page=15`
- Returns: Sales with pagination

**POST** `/api/sales` - Create new sale
```json
{
  "buyer_name": "PT Mitra Jaya",
  "quantity_kg": 500,
  "price_per_kg": 5000,
  "total_price": 2500000,
  "date": "2026-06-20",
  "notes": "Penjualan ke distributor"
}
```

**PUT** `/api/sales/{id}` - Update sale

**DELETE** `/api/sales/{id}` - Delete sale

### 6. Production Costs (Biaya Produksi)

**GET** `/api/costs` - List all costs

**POST** `/api/costs` - Record new cost
```json
{
  "category": "seeds",
  "description": "Bibit kentang",
  "amount": 500000,
  "date": "2026-05-01",
  "notes": "Pembelian bibit berkualitas"
}
```

**PUT** `/api/costs/{id}` - Update cost

**DELETE** `/api/costs/{id}` - Delete cost

### 7. Reports (Laporan)

**GET** `/api/reports/profit-loss` - Get profit/loss report
- Query Params: `start_date`, `end_date`

**GET** `/api/reports/target-vs-actual` - Get target vs actual report

### 8. Settings (Pengaturan)

**GET** `/api/settings` - Get user settings

**POST** `/api/settings/profile` - Update profile
```json
{
  "name": "Nama Baru",
  "phone": "081234567890",
  "farm_name": "Nama Kebun Baru"
}
```

**POST** `/api/settings/password` - Change password
```json
{
  "current_password": "password_lama",
  "new_password": "password_baru",
  "new_password_confirmation": "password_baru"
}
```

**POST** `/api/settings/gudang` - Update warehouse settings
```json
{
  "min_stock": 100,
  "max_stock": 5000
}
```

### 9. Feedback

**POST** `/api/feedback` - Submit feedback
```json
{
  "subject": "Saran fitur",
  "message": "Mohon tambahkan fitur export PDF",
  "rating": 5
}
```

---

## Super Admin Endpoints

### User Management

**GET** `/api/super-admin/users` - List all users

**POST** `/api/super-admin/users` - Create user

**PUT** `/api/super-admin/users/{id}` - Update user

**DELETE** `/api/super-admin/users/{id}` - Delete user

**POST** `/api/super-admin/users/{id}/impersonate` - Impersonate user

### Dashboard Menus

**GET** `/api/super-admin/menus` - List dashboard menus

**POST** `/api/super-admin/menus` - Create menu

**PUT** `/api/super-admin/menus/{id}` - Update menu

**DELETE** `/api/super-admin/menus/{id}` - Delete menu

### Landing Page

**GET** `/api/super-admin/landing` - Get landing content

**POST** `/api/super-admin/landing` - Update landing content

### Feedbacks

**GET** `/api/super-admin/feedbacks` - List all feedbacks

**POST** `/api/super-admin/feedbacks/{id}/read` - Mark feedback as read

**DELETE** `/api/super-admin/feedbacks/{id}` - Delete feedback

---

## Response Format

### Success Response (Status 200, 201)

```json
{
  "success": true,
  "message": "Operation successful",
  "data": {
    // Resource data here
  }
}
```

### Error Response (Status 4xx, 5xx)

```json
{
  "success": false,
  "message": "Error description",
  "data": null
}
```

### Validation Error (Status 422)

```json
{
  "success": false,
  "message": "Validation error",
  "errors": {
    "email": ["Email field is required"],
    "password": ["Password must be at least 8 characters"]
  }
}
```

---

## HTTP Status Codes

- `200` - OK - Request succeeded
- `201` - Created - Resource created successfully
- `400` - Bad Request - Invalid request data
- `401` - Unauthorized - Invalid or missing token
- `403` - Forbidden - Access denied (insufficient permissions)
- `404` - Not Found - Resource not found
- `422` - Unprocessable Entity - Validation error
- `500` - Internal Server Error - Server error

---

## Running with Docker

### Build and Start

```bash
docker-compose up --build
```

### Access API

```
http://localhost:8000/api
```

### Database Management

```bash
# Run migrations
docker-compose exec app php artisan migrate

# Seed database
docker-compose exec app php artisan db:seed

# Access PostgreSQL
docker-compose exec db psql -U postgres -d pertanian_kentang
```

### Stop Services

```bash
docker-compose down
```

### View Logs

```bash
docker-compose logs -f app
docker-compose logs -f db
```

---

## Environment Variables

Create `.env` file with:

```env
APP_NAME="Pertanian Kentang"
APP_ENV=production
APP_DEBUG=false
APP_URL=http://localhost:8000

DB_CONNECTION=pgsql
DB_HOST=db
DB_PORT=5432
DB_DATABASE=pertanian_kentang
DB_USERNAME=postgres
DB_PASSWORD=postgres_password_123

SANCTUM_STATEFUL_DOMAINS=localhost,localhost:8000
```

---

## Rate Limiting

API endpoints have rate limiting (future enhancement):
- Public endpoints: 60 requests per minute
- Authenticated endpoints: 1000 requests per hour

---

## CORS Configuration

CORS is configured to allow requests from:
- `localhost:*`
- `127.0.0.1:*`
- Production domains (configured in `.env`)

---

## Testing API Endpoints

### Using cURL

```bash
# Register
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "farm_name": "Kebun Kentang",
    "name": "Nama User",
    "email": "user@example.com",
    "phone": "081234567890",
    "password": "password123",
    "password_confirmation": "password123"
  }'

# Login
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'

# Get Seasons (with token)
curl -X GET http://localhost:8000/api/seasons \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Using Postman

1. Import API collection from `docs/postman-collection.json`
2. Set `{{base_url}}` variable to `http://localhost:8000/api`
3. Set `{{token}}` variable after login
4. Test endpoints

---

## Troubleshooting

### CORS Errors

Check `config/cors.php` and update allowed origins.

### Token Expired

Get a new token by logging in again.

### Database Connection Errors

Verify Docker container is running:
```bash
docker-compose ps
```

Check environment variables in `.env`.

### Permission Denied

Ensure database migrations have run:
```bash
docker-compose exec app php artisan migrate
```

---

## Support

For issues or questions, please contact the development team.
