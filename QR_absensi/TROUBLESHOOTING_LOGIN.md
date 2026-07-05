# 🔐 Troubleshooting LOGIN Issues

Kalau tidak bisa login di Chrome, ikuti guide ini step-by-step.

---

## 🎯 Pertama: Pastikan Setup Benar

### Checklist:
- [ ] Laragon running (MySQL active)
- [ ] Terminal 1 (Backend): `node index.js` → Status: "Server jalan di http://localhost:5000 ✅"
- [ ] Terminal 2 (Frontend): `npm run dev` → Status: "Local: http://localhost:5173/"
- [ ] Browser buka: `http://localhost:5173/` (BUKAN 5000!)
- [ ] Halaman LOGIN muncul dengan form username & password

Jika salah satu tidak terpenuhi, fix dulu sebelum lanjut.

---

## 🔍 Step 1: Buka Developer Tools

1. Di Chrome, tekan: **F12** atau **Ctrl + Shift + I**
2. Pilih tab: **Console**
3. Pilih tab: **Network**

---

## 🔍 Step 2: Coba Login

1. Masukkan:
   - Username: `admin`
   - Password: `123456`
2. Klik tombol "LOGIN"
3. Perhatikan apa yang terjadi di Console dan Network tab

---

## ✅ Skenario 1: Login BERHASIL (Jangan Panik!)

### Di Console:
```
✅ Login response: {token: "eyJhbGc...", role: "admin"}
```

### Di Network:
```
POST /login → 200 OK
Response: {"message":"Login berhasil","token":"...","role":"admin"}
```

**Solusi:**
- Token berhasil disimpan di localStorage
- Halaman akan reload ke dashboard
- Semuanya OK ✅

---

## ❌ Skenario 2: Login GAGAL - Backend Tidak Bisa Diakses

### Di Console:
```
❌ Login error: Network Error
// atau
❌ Error: Cannot reach http://localhost:5000/login
// atau
❌ CORS error
```

### Penyebab:
1. Backend tidak running
2. Backend error saat startup
3. Port 5000 tidak aktif

### Solusi:

**A. Check Terminal 1 (Backend)**
```bash
cd c:\laragon\www\backend-absensi
node index.js
```

Harus muncul:
```
🔧 index.js file is loading...
Database absensi_qr terkoneksi 🔥
✅ Database initialization completed successfully!
Server jalan di http://localhost:5000 ✅
```

**B. Jika muncul error di Terminal 1:**

Contoh 1: "ECONNREFUSED 127.0.0.1:3306"
```
Solusi: Buka Laragon → Click "Start All" → Tunggu MySQL ready
```

Contoh 2: "Cannot find module 'bcryptjs'"
```bash
cd c:\laragon\www\backend-absensi
npm install
node index.js
```

---

## ❌ Skenario 3: Login GAGAL - Response 401 (Wrong Credentials)

### Di Console:
```
❌ Login error: {"message":"User tidak ditemukan"} 
// atau
❌ Login error: {"message":"Password salah"}
```

### Di Network:
```
POST /login → 401 Unauthorized
Response: {"message":"User tidak ditemukan"}
```

### Penyebab:
1. Username salah
2. Password salah
3. Database kosong (user belum ada)

### Solusi:

**Pastikan user "admin" ada di database:**

Di Terminal 1, lihat log:
```
🌱 Seeded default users with pegawai: admin/123456 & budi/123456
```

Jika ada, berarti seeding berhasil. Coba login lagi dengan:
- Username: `admin`
- Password: `123456`

**Jika tidak ada seeding log, reset database:**

Di Terminal 1, stop dengan Ctrl+C, lalu:
```bash
# Reset database (hapus absensi_qr database)
mysql -u root -e "DROP DATABASE IF EXISTS absensi_qr;"

# Jalankan lagi
node index.js
```

---

## ❌ Skenario 4: Login BERHASIL Tapi Halaman Blank/Error

### Di Console:
```
✅ Login response berhasil, tapi halaman kosong
// atau
❌ Some error trying to fetch data
```

### Penyebab:
1. Frontend error saat fetch data pegawai/divisi/absensi
2. Token tidak disimpan dengan benar
3. localStorage issue

### Solusi:

**A. Refresh halaman: F5**

**B. Clear localStorage:**
```javascript
// Di Console, ketik:
localStorage.clear()
// Kemudian F5
```

**C. Cek localStorage:**
```javascript
// Di Console, ketik:
console.log(localStorage)
// Harus muncul: token, role, username
```

**D. Jika masih error, lihat Network tab:**
1. Di tab Network, lihat request yang error
2. Contoh: GET /pegawai → 403 Forbidden
3. Berarti ada masalah dengan role atau token

---

## ❌ Skenario 5: Token Expired

### Setelah Login, tapi 10 menit kemudian error

```
❌ Token tidak valid
// atau
❌ 403 Forbidden
```

### Penyebab:
Token JWT expire setelah 1 jam (sudah di-set di backend)

### Solusi:
Logout & login ulang

---

## 🧪 Testing Manual dengan CURL/Postman

Jika ingin test endpoint manual:

### Test Login:
```bash
curl -X POST http://localhost:5000/login \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"admin\",\"password\":\"123456\"}"
```

Expected Response:
```json
{
  "message": "Login berhasil",
  "token": "eyJhbGc...",
  "role": "admin"
}
```

### Test Get Pegawai (dengan token):
```bash
curl -X GET http://localhost:5000/pegawai \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

Expected Response:
```json
{
  "data": [
    {
      "id": 1,
      "nama": "admin",
      "divisi_id": null,
      "jabatan": "Administrator",
      "username": "admin",
      "password_raw": "123456"
    },
    ...
  ]
}
```

---

## 📋 Debugging Checklist

Jika masih stuck:

- [ ] MySQL running? (Check Laragon status)
- [ ] Backend running? (Check Terminal 1)
- [ ] Frontend running? (Check Terminal 2)
- [ ] Accessing `http://localhost:5173/`? (NOT 5000!)
- [ ] Check Console (F12 → Console tab)
- [ ] Check Network (F12 → Network tab)
- [ ] Coba F5 refresh
- [ ] Coba localStorage.clear()
- [ ] Coba Close & restart browser
- [ ] Coba Close 2 terminal & restart semua

---

## 🎯 Quick Reference

| Symptom | Likely Cause | Solution |
|---------|--------------|----------|
| Blank page | Frontend error | F5 / clear localStorage |
| Cannot reach server | Backend not running | Check Terminal 1 |
| 401 error | Wrong credentials | Check username/password |
| 403 error | Role issue | Check token & role |
| CORS error | Backend issue | Check CORS in index.js |
| Database error | MySQL not running | Start Laragon |
| Port already in use | Process still running | Kill process / restart |

---

💡 **Pro Tip:** Kalau masih stuck, screenshot error message & share di sini beserta:
- Terminal 1 output
- Console error (F12)
- Network tab error

Itu akan membantu debug lebih cepat!

🚀 Good luck!
