# SIMHPSK API Documentation

## Overview
API documentation lengkap untuk SIMHPSK (Sistem Informasi Manajemen Panen dan Stok Kentang).

Base URL: `http://localhost:8000`

## Authentication

### Login
```http
POST /login
Content-Type: application/x-www-form-urlencoded

email=admin@simhpsk.com&password=admin123
```

**Response (Success):**
```json
{
  "success": true,
  "message": "Login berhasil",
  "user": {
    "id": 1,
    "name": "Admin User",
    "email": "admin@simhpsk.com",
    "role": "admin",
    "status": "active"
  }
}
```

### Register
```http
POST /register
Content-Type: application/x-www-form-urlencoded

farm_name=Pertanian Subur&name=John Doe&email=user@simhpsk.com&phone=081234567890&password=password123&password_confirmation=password123
```

**Response:**
```json
{
  "success": true,
  "message": "Registrasi berhasil, menunggu persetujuan admin"
}
```

### Logout
```http
POST /logout
```

## Protected Routes

Semua route di bawah memerlukan authentication token (session) dari login.

## 1. Dashboard

### Get Dashboard Data
```http
GET /dashboard
```

**Response:**
```json
{
  "totalStok": 1500,
  "totalPenjualan": 45000000,
  "totalBiaya": 25000000,
  "targetPanen": 2000,
  "harvests": [...],
  "transactions": [...],
  "profitLoss": {
    "revenue": 45000000,
    "cost": 25000000,
    "profit": 20000000
  }
}
```

## 2. Seasons (Musim Tanam)

### List Seasons
```http
GET /seasons
```

**Query Parameters:**
- `search` - Cari berdasarkan nama season
- `status` - Filter by status (active, completed, cancelled)

**Response:**
```json
{
  "data": [
    {
      "id": 1,
      "name": "Musim Tanam 1 2024",
      "start_date": "2024-01-01",
      "end_date": "2024-03-31",
      "status": "active",
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "total": 5,
  "currentPage": 1
}
```

### Create Season
```http
POST /seasons
Content-Type: application/x-www-form-urlencoded

name=Musim Tanam 2&start_date=2024-04-01&end_date=2024-06-30&status=active
```

**Response (201 Created):**
```json
{
  "id": 2,
  "name": "Musim Tanam 2",
  "start_date": "2024-04-01",
  "end_date": "2024-06-30",
  "status": "active"
}
```

### Update Season
```http
PUT /seasons/{id}
Content-Type: application/x-www-form-urlencoded

name=Updated Name&status=completed
```

### Delete Season
```http
DELETE /seasons/{id}
```

## 3. Harvests (Panen)

### List Harvests
```http
GET /harvests
```

**Query Parameters:**
- `season_id` - Filter by season
- `status` - Filter by status (recorded, verified, cancelled)

**Response:**
```json
{
  "data": [
    {
      "id": 1,
      "season_id": 1,
      "season_name": "Musim Tanam 1 2024",
      "date": "2024-02-15",
      "weight_kg": 500,
      "notes": "Hasil panen bagus",
      "status": "verified",
      "photo": "/storage/harvests/photo.jpg"
    }
  ]
}
```

### Create Harvest
```http
POST /harvests
Content-Type: multipart/form-data

season_id=1
date=2024-02-15
weight_kg=500
notes=Hasil panen bagus
photo=<file>
status=recorded
```

**Response (201 Created):**
```json
{
  "id": 1,
  "season_id": 1,
  "date": "2024-02-15",
  "weight_kg": 500,
  "status": "recorded",
  "stock_added": true
}
```

### Update Harvest
```http
PUT /harvests/{id}
Content-Type: multipart/form-data

date=2024-02-15
weight_kg=550
status=verified
```

### Delete Harvest
```http
DELETE /harvests/{id}
```

**Response:**
```json
{
  "success": true,
  "message": "Panen dihapus dan stok dikembalikan",
  "stock_returned": 500
}
```

## 4. Stock (Stok Gudang)

### Get Stock Status
```http
GET /stock
```

**Response:**
```json
{
  "current_balance": 1500,
  "min_stock": 100,
  "max_stock": 5000,
  "percentage": 30,
  "status": "normal",
  "transactions_count": 45,
  "recent_transactions": [
    {
      "id": 1,
      "type": "in",
      "amount": 500,
      "date": "2024-02-15",
      "notes": "Panen Musim 1"
    }
  ]
}
```

### Create Outgoing Transaction
```http
POST /stock/outgoing
Content-Type: application/x-www-form-urlencoded

amount=100
notes=Penjualan manual
reference=manual-001
```

**Response:**
```json
{
  "success": true,
  "balance_after": 1400,
  "transaction_id": 45
}
```

## 5. Sales (Penjualan)

### List Sales
```http
GET /sales
```

**Query Parameters:**
- `date_from` - Tanggal mulai
- `date_to` - Tanggal akhir
- `payment_status` - Filter by payment status (paid, unpaid)

**Response:**
```json
{
  "data": [
    {
      "id": 1,
      "date": "2024-02-20",
      "buyer_name": "PT Retail ABC",
      "weight_kg": 200,
      "price_per_kg": 50000,
      "total": 10000000,
      "payment_status": "paid"
    }
  ],
  "summary": {
    "total_sales": 45000000,
    "avg_price": 50000,
    "total_weight": 900
  }
}
```

### Create Sale
```http
POST /sales
Content-Type: application/x-www-form-urlencoded

date=2024-02-20
buyer_name=PT Retail ABC
weight_kg=200
price_per_kg=50000
payment_status=paid
```

**Response (201 Created):**
```json
{
  "id": 1,
  "total": 10000000,
  "stock_deducted": 200
}
```

### Update Sale
```http
PUT /sales/{id}
Content-Type: application/x-www-form-urlencoded

payment_status=paid
```

### Delete Sale
```http
DELETE /sales/{id}
```

**Response:**
```json
{
  "success": true,
  "stock_returned": 200
}
```

## 6. Production Costs (Biaya Produksi)

### List Costs
```http
GET /costs
```

**Query Parameters:**
- `season_id` - Filter by season
- `category` - Filter by category

**Response:**
```json
{
  "data": [
    {
      "id": 1,
      "date": "2024-01-15",
      "season_id": 1,
      "category": "seed",
      "amount": 2000000,
      "notes": "Bibit unggul"
    }
  ],
  "total_by_category": {
    "seed": 2000000,
    "fertilizer": 5000000,
    "pesticide": 1500000,
    "other": 500000
  }
}
```

### Create Cost
```http
POST /costs
Content-Type: application/x-www-form-urlencoded

date=2024-01-15
season_id=1
category=seed
amount=2000000
notes=Bibit unggul
```

### Update Cost
```http
PUT /costs/{id}
```

### Delete Cost
```http
DELETE /costs/{id}
```

## 7. Reports

### Profit & Loss Report
```http
GET /reports/profit-loss
```

**Query Parameters:**
- `season_id` - Filter by specific season

**Response:**
```json
{
  "season": {
    "id": 1,
    "name": "Musim Tanam 1 2024"
  },
  "revenue": 45000000,
  "costs": {
    "total": 25000000,
    "by_category": {
      "seed": 2000000,
      "fertilizer": 5000000,
      "pesticide": 1500000,
      "other": 500000
    }
  },
  "profit": 20000000,
  "profit_margin": 44.4,
  "details": [
    {
      "type": "harvest",
      "description": "Panen 500kg",
      "amount": 25000000
    }
  ]
}
```

### Target vs Actual Report
```http
GET /reports/target-vs-actual
```

**Response:**
```json
{
  "data": [
    {
      "season_id": 1,
      "season_name": "Musim Tanam 1 2024",
      "target_kg": 2000,
      "actual_kg": 1800,
      "percentage": 90
    }
  ],
  "total_target": 5000,
  "total_actual": 4300,
  "average_achievement": 86
}
```

## 8. Settings

### Get Settings
```http
GET /settings
```

**Response:**
```json
{
  "profile": {
    "name": "Admin User",
    "email": "admin@simhpsk.com",
    "phone": "081234567890"
  },
  "gudang": {
    "min_stock": 100,
    "max_stock": 5000
  },
  "notifications": {
    "low_stock": true,
    "new_sale": true,
    "production_cost": true
  }
}
```

### Update Profile
```http
POST /settings/profile
Content-Type: application/x-www-form-urlencoded

name=New Name
email=new@email.com
phone=081234567890
```

### Update Password
```http
POST /settings/password
Content-Type: application/x-www-form-urlencoded

current_password=admin123
password=newpassword123
password_confirmation=newpassword123
```

### Update Gudang Settings
```http
POST /settings/gudang
Content-Type: application/x-www-form-urlencoded

min_stock=150
max_stock=6000
```

## 9. Super Admin Routes

### Get Dashboard Stats
```http
GET /super-admin
```

**Response:**
```json
{
  "total_users": 10,
  "pending_users": 3,
  "active_users": 7,
  "stats": [...]
}
```

### Manage Users

#### List All Users
```http
GET /super-admin/users
```

#### Create User
```http
POST /super-admin/users
Content-Type: application/x-www-form-urlencoded

name=User Name
email=user@simhpsk.com
phone=081234567890
farm_name=Farm Name
role=admin
status=active
password=password123
```

#### Update User
```http
PUT /super-admin/users/{id}
Content-Type: application/x-www-form-urlencoded

role=admin
status=active
approval=approved
```

#### Delete User
```http
DELETE /super-admin/users/{id}
```

### Landing Page Editor

#### Get Landing Content
```http
GET /super-admin/landing-editor
```

#### Update Landing Content
```http
POST /super-admin/landing-editor
Content-Type: application/x-www-form-urlencoded

hero_title=Welcome to SIMHPSK
hero_description=Sistem Informasi Manajemen Panen dan Stok Kentang
feature_1_title=Feature 1
feature_1_description=Description 1
...
```

### Dashboard Menus

#### List Menus
```http
GET /super-admin/menus
```

#### Create Menu
```http
POST /super-admin/menus
Content-Type: application/x-www-form-urlencoded

title=Stok Gudang
icon=bi-box-seam
color=#1A7A4A
description=Kelola stok gudang
sort_order=1
is_active=1
```

#### Update Menu
```http
PUT /super-admin/menus/{id}
```

#### Delete Menu
```http
DELETE /super-admin/menus/{id}
```

## Error Responses

### Validation Error (422)
```json
{
  "errors": {
    "email": ["Email sudah terdaftar"],
    "password": ["Password minimal 6 karakter"]
  }
}
```

### Unauthorized (401)
```json
{
  "message": "Unauthorized"
}
```

### Forbidden (403)
```json
{
  "message": "Forbidden"
}
```

### Not Found (404)
```json
{
  "message": "Not Found"
}
```

## Status Codes

- `200` - OK
- `201` - Created
- `204` - No Content
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `422` - Unprocessable Entity
- `500` - Internal Server Error

## Rate Limiting

Tidak ada rate limiting saat ini. Akan ditambahkan di production.

## CSRF Protection

Semua POST/PUT/DELETE request memerlukan CSRF token di header `X-CSRF-TOKEN` atau form field `_token`.

## Best Practices

1. **Always include error handling** dalam client-side code
2. **Validate input** sebelum mengirim ke server
3. **Use appropriate HTTP methods** (GET, POST, PUT, DELETE)
4. **Check user permissions** sebelum mengakses restricted data
5. **Handle sessions** dengan bijak
6. **Use HTTPS** di production

## Changelog

### Version 1.0 (2024)
- Initial release
- Authentication & Authorization
- Dashboard & Reporting
- CRUD operations
- Super Admin management
