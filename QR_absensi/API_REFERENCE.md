# 🔌 API Reference - QR Code Management Endpoints

Base URL: `http://localhost:5000`

All endpoints require JWT token in Authorization header:
```
Authorization: Bearer {jwt_token}
```

---

## 📝 QR Code Endpoints

### 1️⃣ Generate QR Code for User

```http
POST /qr-code/generate
Content-Type: application/json
Authorization: Bearer {token}

{
  "pegawai_id": 1,
  "tanggal_berlaku": "2024-12-20"
}
```

**Success Response (200):**
```json
{
  "message": "QR Code berhasil dibuat",
  "id": 1,
  "qr_code": "PRESENSI-1-ABC123XYZ",
  "pegawai_nama": "Budi",
  "tanggal_berlaku": "2024-12-20",
  "status": "active"
}
```

**Error Responses:**
```json
// 403 - Not admin
{ "message": "Hanya admin yang dapat membuat QR Code." }

// 400 - Missing fields
{ "message": "pegawai_id dan tanggal_berlaku wajib diisi!" }

// 404 - Pegawai not found
{ "message": "Pegawai tidak ditemukan." }
```

**Status Codes:** 200, 400, 403, 404, 500

---

### 2️⃣ Get QR Codes List

```http
GET /qr-code/list
Authorization: Bearer {token}
```

**Success Response (200):**
```json
{
  "data": [
    {
      "id": 1,
      "qr_code": "PRESENSI-1-ABC123XYZ",
      "tanggal_dibuat": "2024-12-19T10:30:00",
      "tanggal_berlaku": "2024-12-20",
      "tanggal_kadaluarsa": "2024-12-20T23:59:59",
      "status": "active",
      "digunakan_pada": null,
      "pegawai_id": 1,
      "pegawai_nama": "Budi"
    },
    {
      "id": 2,
      "qr_code": "PRESENSI-1-XYZ789ABC",
      "tanggal_dibuat": "2024-12-18T09:15:00",
      "tanggal_berlaku": "2024-12-19",
      "tanggal_kadaluarsa": "2024-12-19T23:59:59",
      "status": "used",
      "digunakan_pada": "2024-12-19T08:30:00",
      "pegawai_id": 1,
      "pegawai_nama": "Budi"
    }
  ]
}
```

**Notes:**
- Admin sees all QR codes
- Non-admin users see only their own QR codes

**Status Codes:** 200, 500

---

### 3️⃣ Scan QR Code - Record Attendance

```http
POST /qr-code/scan
Content-Type: application/json
Authorization: Bearer {token}

{
  "qr_code": "PRESENSI-1-ABC123XYZ"
}
```

**Success Response (200):**
```json
{
  "message": "Absensi berhasil dicatat! ✅",
  "absensi_id": 1,
  "tanggal": "2024-12-20",
  "jam_masuk": "08:30:00",
  "status": "Hadir"
}
```

**Error Responses:**
```json
// 400 - Missing QR code
{ "message": "QR Code wajib diisi!" }

// 404 - QR code not found
{ "message": "QR Code tidak ditemukan atau tidak valid!" }

// 400 - Already used
{ "message": "QR Code ini sudah pernah digunakan!" }

// 400 - Expired
{ "message": "QR Code sudah kadaluarsa!" }

// 403 - Not owner
{ "message": "QR Code ini bukan milik Anda!" }

// 400 - Already attended today
{ "message": "Anda sudah absen hari ini!" }
```

**Validations:**
- QR code must exist
- QR code must not be marked as 'used'
- QR code must not be expired
- QR code must belong to the authenticated user
- User must not have attendance record for today

**Status Codes:** 200, 400, 403, 404, 500

---

### 4️⃣ Delete QR Code

```http
DELETE /qr-code/{id}
Authorization: Bearer {token}
```

**Path Parameters:**
- `id` (integer): QR Code ID to delete

**Success Response (200):**
```json
{
  "message": "QR Code berhasil dihapus"
}
```

**Error Responses:**
```json
// 403 - Not admin
{ "message": "Hanya admin yang dapat menghapus QR Code." }

// 404 - QR code not found
{ "message": "QR Code tidak ditemukan." }

// 400 - Already used
{ "message": "QR Code yang sudah digunakan tidak dapat dihapus!" }
```

**Notes:**
- Only admin can delete QR codes
- Cannot delete QR codes that are already used (status = 'used')

**Status Codes:** 200, 400, 403, 404, 500

---

## 👤 User Management Endpoints

### 5️⃣ Create User Account

```http
POST /user/create
Content-Type: application/json
Authorization: Bearer {token}

{
  "username": "budi123",
  "password": "password123",
  "nama": "Budi Santoso",
  "divisi_id": 1,
  "jabatan": "Programmer"
}
```

**Request Body Parameters:**
- `username` (string, required): Unique username for login
- `password` (string, required): Password (minimum 6 characters)
- `nama` (string, required): Full name of the user
- `divisi_id` (integer, optional): Division ID
- `jabatan` (string, optional): Job position, defaults to "Karyawan"

**Success Response (200):**
```json
{
  "message": "User dan data pegawai berhasil dibuat!",
  "username": "budi123",
  "nama": "Budi Santoso",
  "pegawai_id": 1
}
```

**Error Responses:**
```json
// 403 - Not admin
{ "message": "Hanya admin yang dapat membuat user." }

// 400 - Missing required fields
{ "message": "Username, password, dan nama wajib diisi!" }

// 400 - Username exists
{ "message": "Username sudah terdaftar!" }

// 400 - Password too short
{ "message": "Password minimal 6 karakter!" }
```

**Process:**
1. Create pegawai record with provided name, division, and position
2. Hash password using bcrypt (salt rounds: 10)
3. Create user account with:
   - username
   - hashed password
   - password_raw (for admin reference)
   - role = 'user'
   - pegawai_id = newly created pegawai id

**Status Codes:** 200, 400, 403, 500

---

## 🔗 Existing Endpoints (Reference)

### Login
```http
POST /login
Content-Type: application/json

{
  "username": "admin",
  "password": "123456"
}
```

Returns: JWT token and role

### Get Employees
```http
GET /pegawai
Authorization: Bearer {token}
```

### Get Attendance Records
```http
GET /absensi
Authorization: Bearer {token}
```

### Record Attendance Manually
```http
POST /absensi
Authorization: Bearer {token}

{
  "pegawai_id": 1,
  "tanggal": "2024-12-20",
  "jam_masuk": "08:00",
  "jam_keluar": "17:00",
  "status": "Hadir"
}
```

---

## 📊 Response Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Request successful |
| 400 | Bad Request | Invalid input or validation error |
| 401 | Unauthorized | Invalid or missing token |
| 403 | Forbidden | Access denied (e.g., not admin) |
| 404 | Not Found | Resource not found |
| 500 | Server Error | Internal server error |
| 503 | Service Unavailable | Database not ready |

---

## 🔐 Authentication

All endpoints require JWT token in the Authorization header:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Token structure (decoded):
```json
{
  "id": 1,
  "username": "admin",
  "role": "admin",
  "iat": 1702975200,
  "exp": 1702978800
}
```

Token expiration: 1 hour from creation

---

## 🧪 Testing with cURL

### Generate QR Code
```bash
curl -X POST http://localhost:5000/qr-code/generate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "pegawai_id": 1,
    "tanggal_berlaku": "2024-12-20"
  }'
```

### Get QR Code List
```bash
curl -X GET http://localhost:5000/qr-code/list \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Scan QR Code
```bash
curl -X POST http://localhost:5000/qr-code/scan \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "qr_code": "PRESENSI-1-ABC123XYZ"
  }'
```

### Create User
```bash
curl -X POST http://localhost:5000/user/create \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "username": "budi123",
    "password": "password123",
    "nama": "Budi Santoso",
    "divisi_id": 1,
    "jabatan": "Programmer"
  }'
```

### Get Token (Login First)
```bash
curl -X POST http://localhost:5000/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "123456"
  }'
```

Response includes:
```json
{
  "message": "Login berhasil",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "role": "admin"
}
```

---

## 📋 Pagination & Filtering

Currently not implemented, but can be added:

**Suggested for future:**
```
GET /qr-code/list?status=active&page=1&limit=10
GET /qr-code/list?pegawai_id=1
GET /absensi?date_from=2024-12-01&date_to=2024-12-31
```

---

## 🔄 Rate Limiting

Currently not implemented. Recommended for production:
- 100 requests per minute per IP
- 10 requests per minute for `/login` endpoint

---

## 📚 References

- [QR Code Format](FITUR_BARU.md#database-schema)
- [Backend Implementation](index.js)
- [Frontend Implementation](frontend-absensi/src/App.jsx)
- [Quick Start Guide](QUICK_START.md)
- [Implementation Summary](IMPLEMENTATION_SUMMARY.md)

---

**Last Updated:** December 2024
**API Version:** 1.0.0
