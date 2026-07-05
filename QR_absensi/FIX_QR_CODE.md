# 🔄 Quick Fix: Restart Frontend dengan Clean Install

Jika QR code tidak muncul, coba langkah ini:

## STEP 1: Stop aplikasi
Tekan `Ctrl+C` di terminal/command prompt yang running `npm run dev`

## STEP 2: Clean Frontend Modules

```bash
cd c:\laragon\www\backend-absensi\frontend-absensi

# Hapus node_modules dan package-lock.json
rmdir /s node_modules
del package-lock.json

# Atau di PowerShell:
Remove-Item -Recurse -Force node_modules
Remove-Item package-lock.json
```

## STEP 3: Reinstall Dependencies

```bash
npm install
```

Tunggu sampai selesai (±2-3 menit)

## STEP 4: Restart Frontend

```bash
npm run dev
```

Tunggu sampai muncul:
```
➜  Local:   http://localhost:5173/
```

## STEP 5: Refresh Browser

Buka browser: `http://localhost:5173/`

Tekan: `Ctrl+Shift+Delete` untuk hard refresh (clear cache)

## STEP 6: Test QR Code

1. Login: `budi` / `123456`
2. Buka tab: "⏱️ Catat Presensi & QR"
3. Scroll down ke section: "2. QR Code ID Card Pegawai Anda"
4. Harus terlihat QR code image

---

## 🔍 Jika Masih Tidak Muncul

Buka **Console** (F12 → Console tab) dan lihat error:

### Kalau ada error seperti:
```
Cannot find module 'qrcode'
```

Jalankan:
```bash
npm install qrcode react-qr-reader
npm run dev
```

### Kalau tidak ada error tapi QR masih tidak muncul

Ketik di Console:
```javascript
// Cek data login
console.log(localStorage.getItem('username'))

// Harus muncul nama user (misal: "budi")
```

---

## ✅ Sudah OK?

Kalau sudah berhasil, QR code harusnya:
- ✅ Terlihat gambar QR code
- ✅ Ada text "ID: PG-2" atau ID lainnya di bawahnya
- ✅ Bisa di-scan dengan phone

---

Coba langkah di atas dan report hasilnya! 🚀
