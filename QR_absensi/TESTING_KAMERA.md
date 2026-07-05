# 🎯 TESTING KAMERA - PANDUAN SINGKAT

## ✅ Yang Sudah Diperbaiki:
1. ❌→✅ **Black Screen** - Video seharusnya terlihat sekarang
2. ❌→✅ **Tombol Close** - Tombol "Matikan Kamera" seharusnya bekerja sekarang
3. ❌→✅ **Stream Cleanup** - Kamera cleanup lebih baik

---

## 🧪 Testing Cepat (5 menit)

### Langkah 1: Buka Kamera
1. Login aplikasi
2. Klik **"📷 Buka Kamera Scanner"** (Employee) atau **"📷 Buka Kamera untuk Scan"** (Admin)
3. ⏳ Tunggu 2 detik

### Langkah 2: Verifikasi Video
- ✅ **BAIK**: Video stream terlihat (tidak hitam, bisa lihat kamera)
- ❌ **BURUK**: Hitam / tidak ada video
  - Jika tidak ada, lanjut ke **Troubleshooting** di bawah

### Langkah 3: Test Tombol Close
1. Klik **"📷 Matikan Kamera"**
2. ⏳ Tunggu 1 detik

### Langkah 4: Verifikasi Close
- ✅ **BAIK**: 
  - Kamera menutup dalam 1-2 detik
  - Tombol berubah menjadi "📷 Buka Kamera Scanner"
  - Tidak perlu close web browser
  
- ❌ **BURUK**:
  - Kamera tidak menutup
  - Harus close web browser
  - Lanjut ke **Troubleshooting** di bawah

### Langkah 5: Test Buka/Tutup Berulang
- Buka → Tutup → Buka → Tutup (3x)
- ✅ **BAIK**: Semua lancar
- ❌ **BURUK**: Ada lag/delay, lanjut ke **Troubleshooting**

---

## 🔧 Troubleshooting

### ❌ Masih Black Screen?

**1. Cek Browser Permission:**
- **Chrome**: 
  - Click 🔒 icon → Settings → Allow Camera
- **Firefox**: 
  - Click 🔒 icon → Allow access to camera
- **Edge**: 
  - Click 🔒 icon → Manage → Allow

**2. Buka Browser Console (F12):**
- Lihat ada error gak?
  - `NotAllowedError` → Grant camera permission
  - `NotFoundError` → Kamera tidak terdeteksi
  - Error lainnya → Screenshot dan report

**3. Coba Langkah Ini:**
```
1. Refresh browser (F5 atau Ctrl+R)
2. Wait 3 detik
3. Click tombol kamera lagi
4. Check F12 console untuk error
```

**4. Jika masih tidak bisa:**
- Close semua browser tab
- Open aplikasi di tab baru
- Coba di browser lain (Chrome/Firefox)

---

### ❌ Tombol Close tidak bekerja?

**1. Tunggu Lebih Lama:**
- Click close button
- Wait 2-3 detik (jangan langsung click ulang)

**2. Buka Console (F12):**
- Lihat error? Screenshot dan report

**3. Reload Halaman:**
```
1. Press F5 (refresh page)
2. Login ulang
3. Test kamera lagi
```

**4. Clear Cache:**
```
Press: Ctrl + Shift + Delete
Select: All time
Check: Cookies and other site data + Cached images and files
Click: Clear data
Refresh page
```

---

## ✨ Expected Behavior (Seharusnya Begini)

### Opening Camera:
```
User clicks "📷 Buka Kamera" 
    ↓ (wait 1-2 sec)
Camera opens + video shows
Tombol berubah jadi "📷 Matikan Kamera"
```

### Closing Camera:
```
User clicks "📷 Matikan Kamera"
    ↓ (wait 1 sec)
Camera stops + video disappears
Tombol berubah jadi "📷 Buka Kamera"
(Web browser tetap terbuka - normal)
```

### Scanning QR Code:
```
Camera open + video shows
Point camera to QR code
    ↓ (QR detected)
Scan successful + Camera auto-closes
```

---

## 📋 Checklist Hasil Testing

Setelah testing, report dengan format ini:

**Test Date:** [tanggal]  
**Browser:** [Chrome/Firefox/Edge] Version [versi]  
**Device:** [Desktop/Laptop]  

| Test | Expected | Result | Status |
|------|----------|--------|--------|
| 1. Video shows | Video terlihat | ✅/❌ | Pass/Fail |
| 2. Close button works | Kamera tutup dalam 1-2 sec | ✅/❌ | Pass/Fail |
| 3. No browser close needed | Hanya click button, tidak perlu close web | ✅/❌ | Pass/Fail |
| 4. Repeat open/close | 3x open-close lancar | ✅/❌ | Pass/Fail |
| 5. Scan QR code | QR code terbaca | ✅/❌ | Pass/Fail |

---

## 📞 Kalau Masih Ada Masalah?

1. **Buka Browser Console (F12)**
2. **Try testing 1-2x lagi** (refresh F5 jika perlu)
3. **Screenshot console error** jika ada
4. **Report dengan:**
   - Browser type & version
   - Step yang dilakukan
   - Screenshot/error message
   - Device info (Windows/Mac/Android)

---

**Last Update:** 2026-06-09  
**Status:** ✅ Implemented & Build Success
