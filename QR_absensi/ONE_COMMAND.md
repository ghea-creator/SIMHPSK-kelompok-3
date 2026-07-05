# ⚡ SATU COMMAND - Start Backend + Frontend Bersamaan

## 🎯 Instruksi Super Simple

### LANGKAH 1: Buka Command Prompt atau PowerShell

**Option A: Command Prompt** (Recommended)
```
Windows + R → Ketik "cmd" → Enter
```

**Option B: PowerShell**
```
Windows + R → Ketik "powershell" → Enter
```

### LANGKAH 2: Navigate ke Folder Project

**Command Prompt:**
```bash
cd c:\laragon\www\backend-absensi
```

**PowerShell:**
```powershell
cd c:\laragon\www\backend-absensi
```

### LANGKAH 3: Jalankan Command Ini

**Command Prompt & PowerShell (sama):**
```bash
npm run dev
```

### LANGKAH 4: Tunggu sampai muncul output sukses
```
[0] 🔧 index.js file is loading...
[0] Database absensi_qr terkoneksi 🔥
[0] ✅ Database initialization completed successfully!
[0] Server jalan di http://localhost:5000 ✅

[1] 
[1] ⚛️  VITE v8.0.12  ready in 234 ms
[1] 
[1] ➜  Local:   http://localhost:5173/
```

### LANGKAH 5: Buka Browser
```
http://localhost:5173/
```

### LANGKAH 6: Login
```
Username: admin
Password: 123456
```

---

## 🚀 SELESAI! Aplikasi siap dipakai!

---

## 📋 Penjelasan

### Apa yang terjadi saat `npm run dev`?

Command ini **menjalankan 2 aplikasi sekaligus**:

1. **Backend** - Node.js/Express API di `http://localhost:5000`
2. **Frontend** - React/Vite UI di `http://localhost:5173`

Keduanya berjalan dalam **1 window Command Prompt** menggunakan tools bernama `concurrently`.

### Keuntungan:
- ✅ Cukup 1 command
- ✅ Cukup 1 terminal
- ✅ Lebih simple & mudah
- ✅ Auto-restart saat file berubah

---

## 📦 Available Commands

```bash
# Start KEDUANYA (Backend + Frontend)
npm run dev

# Start HANYA Backend
npm run server

# Start HANYA Frontend
npm run client
```

---

## ⚠️ Penting!

### Jangan Tutup Command Prompt!
Selama menggunakan aplikasi, command prompt harus tetap terbuka. Jika di-close, aplikasi akan berhenti.

### Untuk STOP Aplikasi
Tekan: **Ctrl + C** di command prompt

### Untuk RESTART
```bash
# Tekan Ctrl+C untuk stop
# Lalu ketik: npm run dev
```

---

## ❌ Error & Solusi

### Error: "ECONNREFUSED port 3306"
```
Sebab: MySQL tidak running
Solusi:
  1. Buka Laragon
  2. Click tombol "Start All"
  3. Jalankan lagi: npm run dev
```

### Error: "Port 5000 already in use"
```
Sebab: Ada process lain pakai port 5000
Solusi:
  1. Task Manager (Ctrl+Shift+Esc)
  2. Cari "node"
  3. Kill process
  4. Jalankan: npm run dev
```

### Error: "Cannot find module 'concurrently'"
```
Sebab: Package belum diinstall
Solusi:
  npm install
  npm run dev
```

### Frontend blank / login error
```
1. Tekan F12 di browser
2. Lihat Console tab untuk error message
3. Lihat Network tab apakah request ke backend sukses
```

---

## 💡 Tips & Tricks

### Auto-Reload Frontend
Saat Anda edit file di `src/`, frontend akan otomatis refresh. Tidak perlu refresh manual.

### View Backend Logs
Output dari backend ada di bagian `[0]`, frontend di `[1]`.

### Run Only Backend
Jika hanya ingin develop backend tanpa frontend:
```bash
npm run server
```

### Run Only Frontend
Jika hanya ingin develop frontend tanpa backend:
```bash
npm run client
```

---

## 🎬 Complete Workflow

```
1. Buka Command Prompt
2. cd c:\laragon\www\backend-absensi
3. npm run dev
4. Tunggu 5-10 detik
5. Browser: http://localhost:5173/
6. Login: admin / 123456
7. Mulai develop!
```

---

## ✅ Verification Checklist

- [ ] Laragon running (MySQL aktif)
- [ ] Command Prompt terbuka
- [ ] Sudah ketik: npm run dev
- [ ] Output: Server jalan di http://localhost:5000 ✅
- [ ] Output: Local: http://localhost:5173/
- [ ] Browser terbuka di http://localhost:5173/
- [ ] Login muncul
- [ ] Login berhasil dengan admin/123456
- [ ] Dashboard admin terlihat

---

🎉 **Sekarang Anda bisa develop dengan 1 command saja!**

Next time, cukup:
```bash
cd c:\laragon\www\backend-absensi && npm run dev
```

Selesai! 🚀
