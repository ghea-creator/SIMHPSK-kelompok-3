# 🎯 CARA YANG BENAR - Langkah demi Langkah

## ⚠️ PENTING: 2 Terminal Terpisah!

Backend dan Frontend **HARUS** berjalan di terminal yang berbeda. Ini seperti menjalankan 2 aplikasi.

---

## 📋 Prasyarat
- ✅ Laragon sudah diinstall
- ✅ MySQL sudah berjalan (start dari Laragon)
- ✅ Node.js sudah diinstall

---

## ▶️ STEP 1️⃣: Jalankan Backend

### Opsi A: Menggunakan File .bat (Paling Mudah)
1. Buka File Explorer
2. Navigate ke: `C:\laragon\www\backend-absensi\`
3. **Double-click `START.bat`**
4. Tunggu sampai 2 terminal terbuka dengan pesan sukses

### Opsi B: Manual dengan Command Prompt
1. Buka **Command Prompt / PowerShell**
2. Ketik:
```bash
cd c:\laragon\www\backend-absensi
node index.js
```
3. Tunggu sampai muncul pesan: `Server jalan di http://localhost:5000 ✅`

**Jangan tutup window ini! Biarkan terbuka di background.**

---

## ▶️ STEP 2️⃣: Jalankan Frontend (Terminal BARU!)

1. Buka **Command Prompt / PowerShell yang BARU** (jangan di window yang sama!)
2. Ketik:
```bash
cd c:\laragon\www\backend-absensi\frontend-absensi
npm run dev
```
3. Tungup sampai muncul pesan: `Local: http://localhost:5173/`

**Jangan tutup window ini juga!**

---

## 🌐 STEP 3️⃣: Akses Aplikasi

1. **Buka Browser** (Chrome, Firefox, dll)
2. Ketik di address bar: `http://localhost:5173/`
3. Akan muncul halaman LOGIN

### Login Credentials:
```
Username: admin
Password: 123456
```

---

## 📊 Penjelasan Port

| Aplikasi | Port | URL | Akses |
|----------|------|-----|-------|
| Backend (API) | 5000 | `http://localhost:5000/` | Jangan akses di browser |
| Frontend (Web) | 5173 | `http://localhost:5173/` | ✅ Akses ini di browser |

---

## ✅ Contoh Output yang Benar

### Terminal 1 (Backend) - Harus seperti ini:
```
🔧 index.js file is loading...
🔧 Loading USER CREATION endpoints...
Database absensi_qr terkoneksi 🔥
Column 'role' successfully migrated to table users ⚙️
...
✅ Database initialization completed successfully!
✅ dbInitialized flag set to true
Server jalan di http://localhost:5000 ✅
```

### Terminal 2 (Frontend) - Harus seperti ini:
```
⚛️  Frontend Server Starting...

  VITE v8.0.12  ready in 456 ms

  ➜  Local:   http://localhost:5173/
  ➜  press h to show help
```

---

## ❌ Error & Solusinya

### Error: "ECONNREFUSED 127.0.0.1:3306"
```
❌ DB Error & Inisialisasi Gagal
Error code: ECONNREFUSED
```
**Sebab:** MySQL tidak berjalan
**Solusi:**
1. Buka **Laragon**
2. Klik tombol **"Start All"**
3. Jalankan lagi `node index.js`

---

### Error: "Cannot POST /login"
**Sebab:** Frontend tidak tersambung ke backend
**Solusi:**
1. Cek apakah Terminal 1 (backend) masih running
2. Cek error message di Terminal 1
3. Pastikan backend berhasil connect ke database

---

### Error: "Port 5173 already in use"
```
error: listen EADDRINUSE: address already in use :::5173
```
**Sebab:** Ada proses npm yang masih jalan
**Solusi:**
1. Buka Task Manager (`Ctrl + Shift + Esc`)
2. Cari `node` atau `npm`
3. Kill process tersebut
4. Jalankan `npm run dev` lagi

---

### Frontend Loading Tapi Blank/Error
**Sebab:** Backend tidak berjalan atau ada masalah CORS
**Solusi:**
1. Check Console Browser (`F12` → Console)
2. Lihat error message apa
3. Pastikan Terminal 1 running dan tidak ada error
4. Refresh page (`Ctrl + R` atau `F5`)

---

## 🎬 Demo Flow

```
User Opens File Explorer
         ↓
   Double-click START.bat
         ↓
   [2 Terminal Terbuka]
   Terminal 1: Backend running ✅
   Terminal 2: Frontend running ✅
         ↓
   Browser: http://localhost:5173
         ↓
   LOGIN PAGE muncul
         ↓
   Input: admin / 123456
         ↓
   DASHBOARD ADMIN ✅
```

---

## 💡 Pro Tips

### Jika ingin develop dan auto-reload:
Terminal frontend sudah auto-reload saat file diubah. Tinggal save file, maka browser auto-refresh.

### Jika ingin stop aplikasi:
- Close kedua terminal (atau click X window)
- Atau press `Ctrl + C` di masing-masing terminal

### Jika ingin jalankan di port berbeda:
```bash
# Backend di port 5001
node index.js --port 5001

# Frontend di port 5174
npm run dev -- --port 5174
```

---

## 📞 Troubleshooting Lanjut

Jika masih tidak bisa login:

1. **Check Network Tab**
   - Browser: `F12` → Network
   - Klik tombol Login
   - Lihat apakah request ke `http://localhost:5000/login` berhasil atau error

2. **Check Console Log**
   - Browser: `F12` → Console
   - Lihat error message apa yang muncul

3. **Check Backend Log**
   - Lihat Terminal 1 (Backend)
   - Cari error atau request yang masuk

4. **Restart Semua**
   - Close 2 terminal
   - Close browser
   - Jalankan START.bat lagi

---

🎉 Seharusnya semuanya work now! Good luck! 🚀
