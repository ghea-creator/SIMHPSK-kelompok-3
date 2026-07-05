# 🎫 Fitur Baru - QR Code Management & User Creation

Dokumentasi lengkap untuk fitur-fitur baru yang telah ditambahkan ke sistem PresensiHub.

---

## 📋 Daftar Fitur Baru

### 1. **🎫 QR Code untuk User (Admin Generates, User Scans)**
Admin dapat membuat QR Code unik untuk setiap user, dan user harus datang ke admin untuk menscan QR Code tersebut guna mencatat kehadiran.

### 2. **➕ Pembuatan User Langsung oleh Admin**
Admin dapat membuat akun user baru beserta data pegawainya secara langsung melalui interface tanpa perlu membuat pegawai terlebih dahulu.

---

## 🔧 Backend Endpoints

### 1. Generate QR Code untuk User
**Endpoint:** `POST /qr-code/generate`

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "pegawai_id": 1,
  "tanggal_berlaku": "2024-12-20"
}
```

**Response:**
```json
{
  "message": "QR Code berhasil dibuat",
  "id": 1,
  "qr_code": "PRESENSI-1-ABC123DEF456",
  "pegawai_nama": "Budi",
  "tanggal_berlaku": "2024-12-20",
  "status": "active"
}
```

**Catatan:**
- Hanya admin yang dapat menggunakan endpoint ini
- QR Code akan kadaluarsa pada pukul 23:59:59 pada tanggal berlaku

---

### 2. Daftar QR Code
**Endpoint:** `GET /qr-code/list`

**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
```json
{
  "data": [
    {
      "id": 1,
      "qr_code": "PRESENSI-1-ABC123DEF456",
      "tanggal_dibuat": "2024-12-19T10:30:00",
      "tanggal_berlaku": "2024-12-20",
      "tanggal_kadaluarsa": "2024-12-20T23:59:59",
      "status": "active",
      "digunakan_pada": null,
      "pegawai_id": 1,
      "pegawai_nama": "Budi"
    }
  ]
}
```

**Catatan:**
- Admin melihat semua QR Code
- User hanya melihat QR Code mereka sendiri

---

### 3. Scan QR Code - Catat Absensi
**Endpoint:** `POST /qr-code/scan`

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "qr_code": "PRESENSI-1-ABC123DEF456"
}
```

**Response:**
```json
{
  "message": "Absensi berhasil dicatat! ✅",
  "absensi_id": 1,
  "tanggal": "2024-12-20",
  "jam_masuk": "08:30:00",
  "status": "Hadir"
}
```

**Validasi:**
- QR Code harus valid dan belum digunakan
- QR Code harus milik user yang melakukan scan
- Tidak boleh absen 2x dalam hari yang sama
- QR Code tidak boleh sudah kadaluarsa

---

### 4. Hapus QR Code
**Endpoint:** `DELETE /qr-code/:id`

**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
```json
{
  "message": "QR Code berhasil dihapus"
}
```

**Catatan:**
- Hanya admin yang dapat menghapus
- QR Code yang sudah digunakan tidak dapat dihapus

---

### 5. Buat User Langsung
**Endpoint:** `POST /user/create`

**Headers:**
```
Authorization: Bearer {token}
```

**Request Body:**
```json
{
  "username": "budi123",
  "password": "password123",
  "nama": "Budi Santoso",
  "divisi_id": 1,
  "jabatan": "Programmer"
}
```

**Response:**
```json
{
  "message": "User dan data pegawai berhasil dibuat!",
  "username": "budi123",
  "nama": "Budi Santoso",
  "pegawai_id": 1
}
```

**Catatan:**
- Hanya admin yang dapat membuat user
- Username harus unik
- Password minimal 6 karakter
- Divisi dan jabatan opsional

---

## 👨‍💼 Admin Interface

### Tab: 🎫 QR Code User

**Fitur:**
1. **Generate QR Code**
   - Pilih pegawai dari dropdown
   - Pilih tanggal berlaku
   - Klik "Buat QR Code"
   - QR Code akan muncul dalam format teks

2. **Daftar QR Code**
   - Melihat semua QR Code yang telah dibuat
   - Status: `active` (belum digunakan), `used` (sudah digunakan), `expired` (kadaluarsa)
   - Tombol hapus untuk QR Code yang masih active

### Tab: ➕ Buat User Baru

**Form:**
- Username * (wajib)
- Nama Lengkap * (wajib)
- Password * (wajib, min 6 karakter)
- Konfirmasi Password * (wajib)
- Divisi (opsional)
- Jabatan (opsional)

**Proses:**
1. Isi semua field yang wajib
2. Klik "Buat User"
3. Sistem akan membuat:
   - Data pegawai baru
   - Akun user dengan role "user"
   - Password akan di-hash menggunakan bcrypt

---

## 👤 User Interface

### Tab: 🎫 Scan QR Admin

**Fitur:**
1. **Scanner Kamera**
   - Buka kamera dengan tombol "Buka Kamera untuk Scan"
   - Arahkan kamera ke QR Code yang disiapkan admin
   - Sistem otomatis menscan dan mencatat absensi

2. **Daftar QR Code Aktif**
   - Menampilkan QR Code yang belum digunakan
   - Menampilkan tanggal berlaku dan tanggal kadaluarsa
   - User dapat melihat kapan QR Code mereka expired

---

## 🗄️ Database Schema

### Tabel: `qr_codes`

```sql
CREATE TABLE qr_codes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  pegawai_id INT NOT NULL,
  qr_code VARCHAR(255) NOT NULL UNIQUE,
  tanggal_dibuat TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  tanggal_berlaku DATE NOT NULL,
  tanggal_kadaluarsa DATETIME,
  status ENUM('active', 'used', 'expired', 'deleted') DEFAULT 'active',
  digunakan_pada DATETIME,
  FOREIGN KEY (pegawai_id) REFERENCES pegawai(id) ON DELETE CASCADE,
  INDEX idx_qr_code (qr_code),
  INDEX idx_pegawai_id (pegawai_id),
  INDEX idx_status (status)
)
```

**Kolom:**
- `id`: ID unik QR Code
- `pegawai_id`: Referensi ke user/pegawai
- `qr_code`: Kode QR unik (format: `PRESENSI-{pegawai_id}-{randomCode}`)
- `tanggal_dibuat`: Waktu QR Code dibuat
- `tanggal_berlaku`: Tanggal QR Code berlaku
- `tanggal_kadaluarsa`: Tanggal dan jam QR Code kadaluarsa (23:59:59)
- `status`: Status QR Code (active/used/expired/deleted)
- `digunakan_pada`: Waktu QR Code digunakan

---

## 🔐 Keamanan

1. **Validasi Token JWT**
   - Semua endpoint memerlukan token JWT yang valid
   - Admin-only endpoints dicek dengan `req.user.role === 'admin'`

2. **Validasi Ownership**
   - User hanya dapat scan QR Code yang terdaftar untuk mereka
   - Endpoint `/qr-code/list` menyaring data berdasarkan role

3. **Validasi QR Code**
   - Cek apakah QR Code valid
   - Cek apakah sudah digunakan
   - Cek apakah sudah kadaluarsa
   - Cek apakah milik user yang scan

4. **Password Hashing**
   - Password di-hash menggunakan bcrypt dengan salt 10
   - Password disimpan dalam format `password_raw` untuk referensi admin

---

## 📱 Workflow Contoh

### Scenario: User datang ke admin untuk absen

**Step 1: Admin membuat QR Code**
1. Admin login
2. Pergi ke tab "🎫 QR Code User"
3. Pilih pegawai (misalnya: "Budi")
4. Pilih tanggal hari ini
5. Klik "Buat QR Code"
6. QR Code terbuat (format: `PRESENSI-1-XYZ123`)

**Step 2: Admin display QR Code**
1. Admin menampilkan QR Code ke user (bisa di screen/print)
2. User siap untuk scan

**Step 3: User scan QR Code**
1. User masuk ke aplikasi
2. Pergi ke tab "🎫 Scan QR Admin"
3. Klik "Buka Kamera untuk Scan"
4. User scan QR Code yang ditampilkan admin
5. Sistem otomatis mencatat absensi sebagai "Hadir" hari ini
6. QR Code status berubah menjadi "used"

**Step 4: Admin verify**
1. Admin pergi ke tab "📝 Presensi Pegawai"
2. Lihat absensi Budi tercatat dengan status "Hadir"

---

## ❌ Error Handling

### QR Code tidak ditemukan
```json
{
  "message": "QR Code tidak ditemukan atau tidak valid!"
}
```

### QR Code sudah digunakan
```json
{
  "message": "QR Code ini sudah pernah digunakan!"
}
```

### QR Code kadaluarsa
```json
{
  "message": "QR Code sudah kadaluarsa!"
}
```

### Bukan milik user
```json
{
  "message": "QR Code ini bukan milik Anda!"
}
```

### Sudah absen hari ini
```json
{
  "message": "Anda sudah absen hari ini!"
}
```

### User tidak ditemukan
```json
{
  "message": "User tidak ditemukan"
}
```

---

## 📝 Testing

### Test dengan cURL

**1. Generate QR Code:**
```bash
curl -X POST http://localhost:5000/qr-code/generate \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "pegawai_id": 1,
    "tanggal_berlaku": "2024-12-20"
  }'
```

**2. Get QR Code List:**
```bash
curl -X GET http://localhost:5000/qr-code/list \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**3. Scan QR Code:**
```bash
curl -X POST http://localhost:5000/qr-code/scan \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "qr_code": "PRESENSI-1-ABC123DEF456"
  }'
```

**4. Create User:**
```bash
curl -X POST http://localhost:5000/user/create \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "budi123",
    "password": "password123",
    "nama": "Budi Santoso",
    "divisi_id": 1,
    "jabatan": "Programmer"
  }'
```

---

## 🚀 Deployment Checklist

- [x] Database table `qr_codes` sudah dibuat
- [x] Backend endpoints sudah ditambahkan
- [x] Frontend admin tabs sudah ditambahkan
- [x] Frontend user tab sudah ditambahkan
- [x] Error handling sudah implemented
- [x] Security validation sudah implemented
- [ ] Testing di production environment
- [ ] Update dokumentasi user
- [ ] Training untuk admin dan user

---

## 📞 Support & Troubleshooting

### QR Code tidak ter-generate
- Pastikan user login sebagai admin
- Pastikan pegawai_id valid
- Pastikan tanggal_berlaku dalam format YYYY-MM-DD

### Scanner tidak berfungsi
- Izinkan akses kamera di browser
- Gunakan browser modern (Chrome, Firefox, Safari)
- Pastikan cahaya cukup saat scanning

### Absensi tidak tercatat
- Cek status QR Code (harus "active")
- Cek tanggal dan waktu kadaluarsa
- Pastikan belum absen hari ini
- Pastikan QR Code adalah milik user yang scan

---

**Last Updated:** December 2024
**Version:** 1.0.0
