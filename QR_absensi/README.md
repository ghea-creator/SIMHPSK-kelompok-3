# 🕒 Sistem Absensi QR Code - PresensiHub

Sistem manajemen absensi pegawai berbasis QR code dengan fitur admin dan user.

---

## 🚀 Quick Start (30 Detik)

### ⚡ OPSI 1: SATU COMMAND (RECOMMENDED!)
```bash
npm run dev
```

Atau jika belum di folder project:
```bash
cd c:\laragon\www\backend-absensi && npm run dev
```

**Note:** PowerShell? Gunakan `;` bukan `&&`:
```powershell
cd c:\laragon\www\backend-absensi; npm run dev
```

Tunggu sampai muncul pesan sukses, buka: `http://localhost:5173/`

### OPSI 2: Script Auto
```bash
# Double-click file: START.bat
```

### OPSI 3: Manual (2 Terminal)
```bash
# Terminal 1 (Backend)
cd c:\laragon\www\backend-absensi
node index.js

# Terminal 2 (Frontend) - BUKA TERMINAL BARU
cd c:\laragon\www\backend-absensi\frontend-absensi
npm run dev
```

**Login:** `admin` / `123456`

---

## � NPM Scripts Available

```bash
# Jalankan KEDUANYA (Backend + Frontend) - RECOMMENDED
npm run dev

# Jalankan HANYA Backend (port 5000)
npm run server

# Jalankan HANYA Frontend (port 5173)
npm run client
```

---

| File | Deskripsi |
|------|-----------|
| **QUICK_START.txt** | 📋 Panduan singkat & mudah diikuti |
| **CARA_JALANKAN.md** | 📖 Dokumentasi lengkap cara menjalankan |
| **README_RUN.md** | 📝 Step-by-step dengan troubleshooting |
| **TROUBLESHOOTING_LOGIN.md** | 🔐 Debug masalah login lengkap |
| **PERBAIKAN_ADMIN_ROLE.md** | 🔧 Penjelasan fix admin role check |

---

## 🎯 Fitur Utama

### 👨‍💼 Admin
- ✅ Tambah/Edit/Hapus Pegawai
- ✅ Kelola Divisi
- ✅ Input Absensi Manual
- ✅ Generate QR Code Absensi
- ✅ Persetujuan Cuti Tambahan
- ✅ Laporan Kehadiran

### 👤 User/Karyawan
- ✅ Scan QR untuk Absensi
- ✅ Ajukan Cuti / Izin / Sakit
- ✅ Lihat Rekap Kehadiran
- ✅ Ubah Password

---

## 💻 Tech Stack

| Component | Technology |
|-----------|------------|
| Frontend | React 19 + Vite + Axios |
| Backend | Node.js + Express + JWT |
| Database | MySQL (via Laragon) |
| QR Code | qrcode library |

---

## 📁 Struktur Project

```
backend-absensi/
├── index.js                    ← Backend API (port 5000)
├── START.bat                   ← Script auto-start
├── package.json
├── config/
│   └── db.js                   ← Database config
├── frontend-absensi/           ← Frontend React (port 5173)
│   ├── package.json
│   ├── src/
│   │   ├── App.jsx
│   │   └── ...
│   └── vite.config.js
└── ... (dokumentasi & helper files)
```

---

## 🔐 Login Credentials (Default)

```
Admin:
  Username: admin
  Password: 123456

User Demo:
  Username: budi
  Password: 123456
```

---

## 🌐 Access Points

| Aplikasi | URL | Port | Device |
|----------|-----|------|--------|
| Frontend | http://localhost:5173/ | 5173 | Browser |
| Backend API | http://localhost:5000/ | 5000 | (Internal) |
| Database | localhost | 3306 | MySQL (Laragon) |

---

## ⚙️ Setup Awal (Hanya 1x)

### 1. Install Dependencies
```bash
# Backend
cd c:\laragon\www\backend-absensi
npm install

# Frontend
cd frontend-absensi
npm install
```

### 2. Pastikan Laragon Running
- Buka aplikasi Laragon
- Klik tombol "Start All"
- Tunggu sampai status "Running" (warna hijau)

### 3. Test Backend
```bash
cd c:\laragon\www\backend-absensi
node index.js
```

Harus muncul:
```
✅ Database initialization completed successfully!
Server jalan di http://localhost:5000 ✅
```

---

## ❌ Troubleshooting Cepat

### "ECONNREFUSED 3306" (MySQL tidak running)
```
→ Buka Laragon → Click "Start All"
```

### "Cannot reach http://localhost:5000" (Backend tidak running)
```
→ Buka Terminal 1, check apakah ada error
→ Jalankan: node index.js
```

### "Blank page / Cannot login" (Frontend error)
```
→ Check Console (F12)
→ Check Network tab (F12)
→ Coba: localStorage.clear() lalu F5
```

### "Port already in use"
```
→ Task Manager → Cari "node" → Kill process
→ Jalankan lagi
```

**Untuk troubleshooting detail, lihat:** [TROUBLESHOOTING_LOGIN.md](TROUBLESHOOTING_LOGIN.md)

---

## 📊 Database Schema

### Tabel Utama:
- **users** - Akun login (id, username, password, role, pegawai_id)
- **pegawai** - Data karyawan (id, nama, divisi_id, jabatan)
- **divisi** - Departemen (id, nama_divisi)
- **absensi** - Catatan kehadiran (id, pegawai_id, tanggal, jam_masuk, jam_keluar, status)
- **cuti_tambahan** - Ajuan cuti khusus (id, pegawai_id, tanggal_mulai, tanggal_selesai, status)

---

## 🔄 API Endpoints

### Authentication
```
POST   /login                 - Login user
POST   /register              - Register user baru
POST   /change-password       - Ubah password
```

### Pegawai Management
```
GET    /pegawai               - List semua pegawai
POST   /pegawai               - Tambah pegawai (Admin only)
PUT    /pegawai/:id           - Edit pegawai (Admin only)
DELETE /pegawai/:id           - Hapus pegawai (Admin only)
```

### Divisi Management
```
GET    /divisi                - List divisi
POST   /divisi                - Tambah divisi (Admin only)
```

### Absensi
```
GET    /absensi               - List absensi
POST   /absensi               - Input absensi manual/QR scan
```

### Cuti
```
GET    /cuti                  - List ajuan cuti
POST   /cuti                  - Ajukan cuti
PUT    /cuti/:id              - Approve/Reject cuti (Admin)
```

### QR Code
```
GET    /generate-office-qr    - Generate QR kantor (Admin)
GET    /qr-code/list          - List QR codes
POST   /qr-code/generate      - Generate QR code custom
```

---

## 🔒 Keamanan

- ✅ Password di-hash dengan bcryptjs
- ✅ Authentication via JWT (Bearer Token)
- ✅ Role-based access control (Admin / User)
- ✅ CORS enabled untuk frontend
- ✅ Admin-only endpoints protected

---

## 🐛 Known Issues & Fixes

### Issue: Admin tidak bisa tambah pegawai
**Status:** ✅ FIXED (v1.1)
**Detail:** Menambahkan role check ke POST /pegawai endpoint
**File:** PERBAIKAN_ADMIN_ROLE.md

---

## 📞 Support

Jika ada masalah:

1. Check file dokumentasi di atas
2. Baca TROUBLESHOOTING_LOGIN.md
3. Lihat error message di Console (F12)
4. Check Terminal 1 & 2 output

---

## 📜 Changelog

### v1.1 (Current)
- ✅ Fix: Admin role check pada CRUD endpoints
- ✅ Add: Comprehensive documentation
- ✅ Add: Auto-start script (START.bat)
- ✅ Add: Troubleshooting guides

### v1.0
- Initial release

---

## 📝 License

Internal use only for Absensi System

---

**Last Updated:** June 1, 2026
**Status:** ✅ Production Ready

Selamat menggunakan PresensiHub! 🚀
