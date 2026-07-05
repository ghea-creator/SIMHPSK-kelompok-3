# 🚀 Quick Start Guide - Fitur QR Code & User Creation

Panduan cepat menggunakan fitur-fitur baru di PresensiHub.

---

## 🎯 Untuk Admin

### ✅ Membuat User Baru

1. **Login sebagai admin**
   - Username: `admin`
   - Password: `123456` (default)

2. **Pergi ke tab "➕ Buat User Baru"**

3. **Isi form:**
   - **Username**: username unik untuk user (misal: `budi123`)
   - **Nama Lengkap**: nama lengkap user (misal: `Budi Santoso`)
   - **Password**: password minimal 6 karakter
   - **Konfirmasi Password**: ulangi password
   - **Divisi**: pilih divisi dari dropdown (opsional)
   - **Jabatan**: masukkan jabatan user (opsional)

4. **Klik "✨ Buat User"**
   - User akan berhasil dibuat
   - User bisa login dengan username dan password yang baru

---

### 🎫 Membuat QR Code untuk User

1. **Pergi ke tab "🎫 QR Code User"**

2. **Bagian "Buat QR Code untuk User":**
   - **Pilih Pegawai**: dropdown untuk memilih user (misal: `Budi Santoso`)
   - **Tanggal Berlaku**: pilih tanggal kapan QR berlaku (default: hari ini)
   - Klik "✨ Buat QR Code"

3. **QR Code akan muncul:**
   - QR Code ditampilkan dalam format teks (misal: `PRESENSI-1-ABC123XYZ`)
   - Anda dapat:
     - Screenshot QR Code
     - Print QR Code
     - Share ke user

4. **Bagian "Daftar QR Code":**
   - Melihat semua QR Code yang telah dibuat
   - Status QR Code:
     - 🟦 `active` = belum digunakan, user bisa scan
     - 🟩 `used` = sudah digunakan, user sudah absen
     - ⚫ `expired` = sudah kadaluarsa, tidak bisa digunakan lagi
   - Tombol ❌ untuk menghapus QR Code yang masih active

---

### 📊 Workflow Absensi dengan QR Code

**Saat user datang ke kantor:**

1. Admin: Buat QR Code untuk user hari ini
2. Admin: Tampilkan QR Code ke user (bisa di screen/print)
3. User: Scan QR Code menggunakan handphone
4. Admin: Lihat di tab "📝 Presensi Pegawai" bahwa user sudah absen

**Keuntungan:**
- User tidak perlu ambil foto/video bukti
- Admin dapat mengontrol kapan/berapa user yang hadir
- Tidak ada kemungkinan user absen dari rumah
- Audit trail yang jelas (kapan QR dibuat, kapan digunakan)

---

## 👤 Untuk User

### 📱 Cara Absen dengan QR Code Admin

**Persyaratan:**
- Datang ke kantor tempat admin berada
- Handphone dengan kamera yang berfungsi
- Sudah login di aplikasi PresensiHub

**Langkah:**

1. **Login ke aplikasi**
   - Username: username Anda
   - Password: password Anda

2. **Pergi ke tab "🎫 Scan QR Admin"**

3. **Lihat "QR Code Anda yang Aktif"**
   - Akan melihat tanggal berlaku QR Code Anda
   - Jika tidak ada, tanya ke admin untuk membuat QR Code

4. **Klik "📷 Buka Kamera untuk Scan"**

5. **Arahkan kamera ke QR Code yang ditampilkan admin**
   - Pastikan cahaya cukup
   - QR Code harus terlihat jelas di layar
   - Tunggu sampai sistem scan otomatis

6. **Sistem akan menampilkan pesan sukses**
   - ✅ "Absensi berhasil dicatat! ✅"
   - Anda sudah berhasil absen hari ini

7. **Klik tab "⏱️ Catat Presensi & QR"**
   - Di bagian "Riwayat Absensi Saya" lihat absensi Anda tadi

---

### ⏱️ Cara Absen Mandiri dengan QR Code Kantor

Jika admin membuat QR Code Kantor:

1. **Pergi ke tab "⏱️ Catat Presensi & QR"**

2. **Bagian "1. Scan QR Code Kantor":**
   - Klik "📷 Buka Kamera Scanner"
   - Arahkan ke QR Code yang ditampilkan di screen/monitor kantor
   - Sistem akan otomatis mencatat absensi

3. **Bagian "⚡ Uji Coba Absen (Simulator)":**
   - Jika tidak ada kamera, bisa gunakan tombol simulasi:
     - 🟢 **Hadir**: absen dengan status Hadir
     - 🟡 **Izin**: absen dengan status Izin
     - 🔴 **Sakit**: absen dengan status Sakit
   - (Catatan: Simulator hanya untuk testing, tidak boleh di-production)

---

## ⚠️ Hal-hal Penting

### Untuk Admin

1. **Password User**
   - Admin bertanggung jawab membuat password yang aman
   - Jangan share password di public chat

2. **QR Code**
   - QR Code berlaku sampai pukul 23:59:59 pada tanggal berlaku
   - Admin bisa hapus QR Code yang belum digunakan
   - QR Code yang sudah digunakan tidak bisa dihapus

3. **Laporan Absensi**
   - Lihat di tab "📝 Presensi Pegawai" untuk melihat siapa yang sudah absen
   - Update real-time setiap kali user scan QR

### Untuk User

1. **Absensi Harian**
   - Hanya bisa absen 1x per hari
   - Kalo scan lagi, akan muncul error "Anda sudah absen hari ini"

2. **QR Code Validity**
   - QR Code hanya berlaku 1 hari
   - Kalo tidak absen hari ini, besok harus minta QR Code baru

3. **Batasan Izin/Sakit**
   - Izin + Sakit max 7 hari per bulan
   - Kalo lebih, harus ajukan "Cuti Tambahan"

---

## 🎓 Contoh Use Case

### Scenario: Absensi Pagi Karyawan di Kantor

**08:00 - Admin Setup**
- Admin login ke sistem
- Pergi ke "🎫 QR Code User"
- Buat QR Code untuk semua karyawan yang diharapkan hadir hari ini
- QR Code ditampilkan di layar LCD di depan entrance kantor

**08:15 - Karyawan Datang**
- Karyawan datang ke kantor
- Lihat QR Code di layar LCD
- Buka app PresensiHub
- Pergi ke tab "🎫 Scan QR Admin"
- Scan QR Code
- ✅ Absensi berhasil dicatat

**08:30 - Admin Monitor**
- Admin pergi ke "📝 Presensi Pegawai"
- Lihat daftar karyawan yang sudah absen
- Update real-time

---

## 🆘 FAQ

**Q: Apa bedanya "Scan QR Admin" dengan "Catat Presensi & QR"?**

A:
- **Scan QR Admin**: User datang ke admin, admin display QR Code, user scan
  - Lebih aman (admin kontrol siapa yang boleh absen)
  - Tidak perlu koneksi internet di lokasi karyawan
  
- **Catat Presensi & QR**: User self-service, scan QR Code yang sudah ada di kantor
  - Lebih fleksibel
  - Karyawan bisa absen kapan saja

**Q: Apakah user bisa absen dari rumah dengan QR Code?**

A: Tidak, user harus datang ke admin untuk scan QR Code yang admin generate. Ini adalah fitur keamanan untuk memastikan karyawan benar-benar datang ke kantor.

**Q: Bagaimana kalau QR Code tidak muncul?**

A: Hubungi admin untuk:
1. Pastikan QR Code sudah dibuat untuk hari ini
2. Refresh halaman
3. Coba logout dan login lagi
4. Clear browser cache

**Q: Apakah bisa buat QR Code untuk besok?**

A: Ya, saat membuat QR Code, bisa pilih tanggal berlaku kapan saja. Tapi QR Code hanya bisa digunakan pada tanggal berlaku tersebut.

---

**Semoga bermanfaat! Jika ada pertanyaan, hubungi admin atau lihat dokumentasi lengkap di FITUR_BARU.md**
