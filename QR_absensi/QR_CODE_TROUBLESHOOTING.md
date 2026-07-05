# 🔧 Troubleshooting QR Code User tidak Terbuka

## 🎯 Ada 2 Jenis QR Code untuk User

### 1. **QR Code ID Card Pegawai** (Tab: Catat Presensi & QR)
   - Adalah QR code personal user yang di-generate otomatis
   - Menampilkan data: ID, Nama, Jabatan, Divisi
   - Untuk di-scan di alat pemindai kantor

### 2. **Scan QR Code dari Admin** (Tab: Scan QR Admin)
   - User membuka kamera untuk scan QR code yang disiapkan admin
   - Perlu permission kamera browser

---

## 🔍 Step-by-Step Troubleshooting

### STEP 1: Buka Developer Console
```
Tekan: F12 di browser
Pilih Tab: Console
```

### STEP 2: Login sebagai User
```
Username: budi
Password: 123456
```

### STEP 3: Cek Tab "Catat Presensi & QR"
Harusnya ada section:
```
2. QR Code ID Card Pegawai Anda
```

Kalau tidak ada QR code yang muncul, lihat console untuk error.

---

## ❌ Error 1: "Cannot find module 'qrcode'"

### Error Message:
```
Cannot find module 'qrcode' from App.jsx
```

### Penyebab:
Package `qrcode` belum di-install di frontend

### Solusi:
```bash
cd c:\laragon\www\backend-absensi\frontend-absensi
npm install qrcode
npm run dev
```

---

## ❌ Error 2: QR Code Tidak Muncul, Hanya Text "Membuat QR Code..."

### Penyebab:
1. Effect tidak trigger karena dependency issue
2. currentEmployee tidak terload
3. pegawai data kosong

### Debug Steps:

Di Console, ketik:
```javascript
// Cek apakah currentEmployee ada
console.log(localStorage.getItem('username'))
// Harus muncul: "budi" (atau username Anda)

// Lihat Console → Check apakah ada error saat generate QR
```

Di App.jsx, tambahkan console.log untuk debug:
```javascript
// Line 209: Di dalam useEffect
useEffect(() => {
  if (role === 'user' && pegawai.length > 0) {
    const loggedInUser = localStorage.getItem('username') || username;
    console.log('👤 Logged in user:', loggedInUser);
    console.log('📊 Pegawai list:', pegawai);
    
    const matched = pegawai.find(
      (p) => p.nama.toLowerCase() === loggedInUser.toLowerCase()
    );
    console.log('🔍 Matched employee:', matched);
    
    if (matched) {
      setCurrentEmployee(matched);
      // ...generate QR code...
      QRCode.toDataURL(qrData, { width: 180, margin: 2 }, (err, url) => {
        if (err) {
          console.error('❌ QR Code generation error:', err);
        } else {
          console.log('✅ QR Code generated successfully');
          setEmployeeQrCode(url);
        }
      });
    }
  }
}, [role, pegawai, username]);
```

---

## ❌ Error 3: Camera/Scanner Error

### Error Message (di Console):
```
NotAllowedError: Permission denied
// atau
NotFoundError: Requested device not found
```

### Penyebab:
1. Browser tidak dapat akses kamera
2. Kamera tidak di-izinkan di browser settings
3. Tidak ada kamera di device

### Solusi:

**A. Check Camera Permission:**
1. Chrome → Settings → Privacy & Security → Site settings
2. Cari "Camera"
3. Ensure domain `localhost:5173` allowed

**B. Check di App:**
1. Klik tombol "📷 Buka Kamera untuk Scan"
2. Browser akan minta permission (Allow/Deny)
3. Click "Allow"

**C. Kalau masih error:**
- Gunakan simulator buttons (Hadir, Izin, Sakit) sebagai ganti
- Atau gunakan device lain dengan kamera

---

## ❌ Error 4: QR Code Image Blank/Corrupted

### Gejala:
QR code ada tapi gambarnya blank atau tidak bisa di-scan

### Penyebab:
QRCode.toDataURL callback error atau timeout

### Solusi:
Update code dengan error handling:

```javascript
QRCode.toDataURL(qrData, { width: 180, margin: 2 }, (err, url) => {
  if (err) {
    console.error('❌ QR Error:', err);
    showToast('Gagal generate QR Code', 'error');
  } else if (url) {
    console.log('✅ QR Generated:', url.substring(0, 50) + '...');
    setEmployeeQrCode(url);
  }
});
```

---

## ✅ Verify QR Code Works

### Test QR Code Scanning:

1. **Use Online QR Scanner:**
   - Buka: https://online-qr-code-generator.com/ 
   - Upload screenshot QR code Anda
   - Klik "Scan"
   - Harus muncul data JSON:
     ```json
     {
       "id": 2,
       "nama": "budi",
       "jabatan": "Karyawan",
       "divisi": "Tanpa Divisi",
       "type": "EMPLOYEE-QR-ID"
     }
     ```

2. **Use Phone Scanner:**
   - Print/Screenshot QR code
   - Scan dengan phone camera
   - Harus bisa baca data

---

## 📋 Verification Checklist

- [ ] Login sebagai user (budi)
- [ ] Buka tab "Catat Presensi & QR"
- [ ] Section "2. QR Code ID Card Pegawai Anda" terlihat
- [ ] QR code image muncul (bukan "Membuat QR Code...")
- [ ] QR code bisa di-scan dengan phone
- [ ] Tab "Scan QR Admin" → bisa buka kamera
- [ ] Console tidak ada error merah

---

## 🎯 Quick Fixes

### Kalau QR code masih tidak muncul:

1. **Refresh page:**
   ```
   F5 atau Ctrl+R
   ```

2. **Clear cache & localStorage:**
   ```javascript
   // Di Console:
   localStorage.clear()
   location.reload()
   ```

3. **Restart application:**
   ```bash
   # Stop: Ctrl+C
   npm run dev
   ```

4. **Reinstall packages:**
   ```bash
   cd frontend-absensi
   rm -r node_modules package-lock.json
   npm install
   npm run dev
   ```

---

## 🐛 Masalah Spesifik yang Mungkin

### "QR Reader tidak bisa di-import"
**Solusi:** `npm install react-qr-reader`

### "QRCode.toDataURL undefined"
**Solusi:** `npm install qrcode`

### "Effect tidak trigger"
**Debug:** Console.log di setiap condition di effect

### "Data username tidak match"
**Debug:** 
```javascript
console.log('Username dari localStorage:', localStorage.getItem('username'))
console.log('Pegawai list names:', pegawai.map(p => p.nama))
```

---

## 📞 Kalau Masih Stuck

Berikan saya:
1. Screenshot atau screenshot error di Console (F12)
2. Output dari: `console.log(localStorage.getItem('username'))`
3. Apakah QR code image ada (hanya blank) atau sama sekali tidak ada?
4. Error message (jika ada) dari Console tab

---

Good luck! 🚀
