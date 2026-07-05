# 🚀 Cara Menjalankan Backend & Frontend

Sistem ini terdiri dari 2 aplikasi terpisah yang harus berjalan bersamaan:

## 📋 Struktur Project
```
backend-absensi/
├── index.js                  ← Backend (Node.js/Express)
├── package.json
├── config/
├── frontend-absensi/         ← Frontend (React/Vite) 
│   ├── package.json
│   ├── src/
│   └── vite.config.js
└── ... (file lainnya)
```

---

## 🔧 Setup Awal (Hanya 1x)

### 1️⃣ Install Dependencies Backend
```bash
cd c:\laragon\www\backend-absensi
npm install
```

### 2️⃣ Install Dependencies Frontend
```bash
cd c:\laragon\www\backend-absensi\frontend-absensi
npm install
```

---

## ▶️ Jalankan Aplikasi (Setiap kali ingin start)

### ⚡ METODE 1: SATU COMMAND (RECOMMENDED!)

Hanya perlu 1 command untuk start keduanya:

```bash
cd c:\laragon\www\backend-absensi
npm run dev
```

Tunggu sampai muncul:
```
[0] Server jalan di http://localhost:5000 ✅
[1] ➜  Local:   http://localhost:5173/
```

Buka browser: `http://localhost:5173/`

---

### METODE 2: Gunakan 2 Terminal Terpisah

### Terminal 1️⃣ - Backend Server
```bash
cd c:\laragon\www\backend-absensi
node index.js
```

**Output yang benar:**
```
🔧 index.js file is loading...
Database absensi_qr terkoneksi 🔥
✅ Database initialization completed successfully!
Server jalan di http://localhost:5000 ✅
```

---

### Terminal 2️⃣ - Frontend Development Server
```bash
cd c:\laragon\www\backend-absensi\frontend-absensi
npm run dev
```

**Output yang benar:**
```
  VITE v8.0.12  ready in 123 ms

  ➜  Local:   http://localhost:5173/
  ➜  press h to show help
```

---

## 🌐 Akses Aplikasi

Setelah kedua server running:
1. **Buka Browser** → `http://localhost:5173/`
2. **Login dengan:**
   - Username: `admin`
   - Password: `123456`

---

## ✅ Checklist

- [ ] MySQL/Laragon sudah running (port 3306)
- [ ] Terminal 1: Backend running di `http://localhost:5000` ✅
- [ ] Terminal 2: Frontend running di `http://localhost:5173` ✅
- [ ] Browser bisa akses `http://localhost:5173` ✅
- [ ] Login berhasil dengan admin/123456 ✅

---

## 🆘 Troubleshooting

### ❌ "Cannot GET /" di localhost:5000
**Sebab:** Membuka port 5000 di browser (itu backend API, bukan web)
**Solusi:** Akses `http://localhost:5173/` (frontend) bukan `http://localhost:5000/`

### ❌ "Failed to connect to backend"
**Sebab:** Backend tidak running atau port 5000 tidak aktif
**Solusi:** 
1. Check Terminal 1 - apakah `node index.js` running?
2. Cek error di Terminal 1
3. Pastikan MySQL aktif (Laragon running)

### ❌ "ECONNREFUSED 127.0.0.1:3306"
**Sebab:** MySQL tidak running
**Solusi:**
1. Buka Laragon
2. Click tombol "Start All"
3. Jalankan ulang `node index.js`

### ❌ "Cannot find module 'axios'" di frontend
**Sebab:** npm dependencies frontend belum diinstall
**Solusi:**
```bash
cd c:\laragon\www\backend-absensi\frontend-absensi
npm install
npm run dev
```

### ❌ "Port 5173 already in use"
**Sebab:** Ada proses lain yang pakai port 5173
**Solusi:**
```bash
# Gunakan port berbeda
npm run dev -- --port 5174
```

---

## 📝 Quick Command

Untuk mempermudah, buat file batch `START_APP.bat` di root project:

```batch
@echo off
start "Backend" cmd /k "cd c:\laragon\www\backend-absensi && node index.js"
start "Frontend" cmd /k "cd c:\laragon\www\backend-absensi\frontend-absensi && npm run dev"
pause
```

Kemudian double-click file tersebut untuk start kedua aplikasi sekaligus!
