# SIMHPSK — Sistem Informasi Manajemen Hasil Pertanian & Stok Kentang

**Kelompok 3**

Aplikasi manajemen usaha tani kentang berbasis web (Laravel API) dengan aplikasi pendamping mobile (Flutter), dibuat untuk membantu petani mencatat musim tanam, hasil panen, stok gudang, penjualan, dan biaya produksi, serta menghasilkan laporan laba-rugi dan target vs realisasi secara otomatis.

---

## Daftar Isi

1. [Profil & Pengenalan Aplikasi](#1-profil--pengenalan-aplikasi)
2. [Fitur/Fungsi Aplikasi](#2-fitur-fungsi-aplikasi)
3. [Tampilan Aplikasi](#3-tampilan-aplikasi)
4. [Cara Penggunaan](#4-cara-penggunaan)
5. [Infrastruktur](#5-infrastruktur)
6. [Instalasi Teknis](#6-instalasi-teknis)
7. [Struktur Proyek](#7-struktur-proyek)
8. [Tim Pengembang](#8-tim-pengembang)

---

## 1. Profil & Pengenalan Aplikasi

**SIMHPSK** (Sistem Informasi Manajemen Hasil Pertanian & Stok Kentang) adalah platform digital yang dirancang untuk membantu petani kentang mengelola seluruh siklus usaha taninya dalam satu sistem terintegrasi — mulai dari perencanaan musim tanam, pencatatan hasil panen, pengelolaan stok gudang, pencatatan penjualan dan biaya produksi, hingga pelaporan keuangan otomatis.

Sebelumnya, pencatatan semacam ini umumnya dilakukan manual (buku catatan atau spreadsheet terpisah) sehingga rawan human error, sulit dilacak, dan tidak memberi gambaran untung-rugi secara real-time. SIMHPSK mengatasi masalah itu dengan menyediakan API terpusat yang dapat diakses melalui aplikasi mobile, sehingga petani dapat mencatat aktivitas tani langsung dari lapangan menggunakan ponsel.

**Target pengguna:**
- **Petani (role `user`)** — mencatat musim tanam, panen, stok, penjualan, dan biaya produksi miliknya sendiri, serta melihat laporan usahanya.
- **Super Admin (role `super_admin`)** — mengelola seluruh akun petani, memantau data lintas pengguna, mengelola konten landing page, dan menangani feedback pengguna.

---

## 2. Fitur/Fungsi Aplikasi

### Manajemen Data Usaha Tani
- **Musim Tanam (Season)** — mencatat periode tanam, tanggal mulai/selesai, status (aktif/selesai/dibatalkan), dan target hasil panen (kg).
- **Panen (Harvest)** — mencatat hasil panen per musim tanam lengkap dengan berat (kg), tanggal, catatan, dan foto bukti panen.
- **Stok Gudang (Stock)** — mencatat stok masuk dan keluar, dengan riwayat transaksi dan saldo berjalan.
- **Penjualan (Sale)** — mencatat transaksi penjualan hasil panen: pembeli, jumlah/berat, harga per satuan, dan status pembayaran (lunas/belum lunas).
- **Biaya Produksi (Cost)** — mencatat pengeluaran per kategori (bibit, pupuk, pestisida, lainnya) yang terhubung ke musim tanam.

### Pelaporan
- **Laporan Laba-Rugi (Profit & Loss)** — menghitung otomatis pendapatan (dari penjualan) dikurangi biaya produksi, dapat difilter per musim tanam.
- **Laporan Target vs Realisasi** — membandingkan target hasil panen yang direncanakan dengan hasil aktual.
- **Ekspor Laporan** — kedua laporan di atas dapat diunduh dalam format **Excel** dan **PDF**.

### Fitur Pendukung
- **Autentikasi & Keamanan** — register, login, logout, lupa/reset password berbasis token (Laravel Sanctum).
- **Notifikasi** — pemberitahuan dalam aplikasi terkait aktivitas akun.
- **Feedback** — pengguna dapat mengirim masukan/laporan kendala ke admin.
- **Chatbot (TaniBot)** — asisten chat sederhana terintegrasi n8n untuk membantu pengguna.
- **Pengaturan Akun** — kelola profil, ubah password, preferensi gudang dan notifikasi, serta hapus akun.

### Panel Super Admin
- Kelola seluruh akun pengguna (buat, ubah, hapus, approve/reject pendaftaran).
- **Impersonate** — masuk sebagai pengguna tertentu untuk keperluan dukungan/troubleshooting.
- Kelola konten landing page publik.
- Kelola menu dashboard.
- Kelola dan tinjau feedback dari seluruh pengguna.

---

## 3. Tampilan Aplikasi

> Tempelkan screenshot aplikasi (mobile app & landing page) di bagian ini. Contoh format:
>
> | Login | Dashboard | Catat Panen | Laporan |
> |---|---|---|---|
> | ![Login](docs/screenshots/login.png) | ![Dashboard](docs/screenshots/dashboard.png) | ![Panen](docs/screenshots/harvest.png) | ![Laporan](docs/screenshots/report.png) |
>
> *(Buat folder `docs/screenshots/` di repo, upload gambar hasil screenshot aplikasi mobile & web, lalu ganti path di atas sesuai nama file kamu.)*

---

## 4. Cara Penggunaan

### Alur Dasar Pengguna (Petani)

1. **Registrasi & Login** — buat akun baru melalui aplikasi mobile, login menggunakan email dan password.
2. **Buat Musim Tanam** — tentukan nama musim, tanggal mulai-selesai, dan target hasil panen (kg).
3. **Catat Panen** — setiap kali panen, catat berat hasil panen, tanggal, dan (opsional) foto bukti, terhubung ke musim tanam yang aktif.
4. **Kelola Stok** — catat stok masuk (hasil panen yang disimpan) dan stok keluar (terjual/dipakai).
5. **Catat Penjualan** — saat menjual hasil panen, catat data pembeli, jumlah, harga per kg, dan status pembayaran.
6. **Catat Biaya Produksi** — masukkan pengeluaran (bibit, pupuk, pestisida, dll) selama musim tanam berjalan.
7. **Lihat Laporan** — buka menu laporan untuk melihat laba-rugi dan capaian target vs realisasi; unduh dalam format Excel/PDF bila diperlukan.

### Alur Admin (Super Admin)

1. Login menggunakan akun dengan role `super_admin`.
2. Buka dashboard admin untuk melihat ringkasan seluruh pengguna.
3. Kelola akun pengguna: approve pendaftaran baru, ubah data, atau nonaktifkan akun bermasalah.
4. Tinjau dan tanggapi feedback yang masuk dari pengguna.
5. Kelola konten landing page dan menu dashboard sesuai kebutuhan.

---

## 5. Infrastruktur

| Layer | Teknologi |
|---|---|
| **Backend API** | Laravel 13 (PHP 8.3), RESTful API |
| **Autentikasi** | Laravel Sanctum (token-based) |
| **Database** | SQLite (development/testing) / MySQL 8.0 (production) |
| **Cache** | Redis 7 |
| **Web Server (production)** | Nginx + PHP-FPM (1 container) |
| **Ekspor Dokumen** | `maatwebsite/excel` (Excel), `barryvdh/laravel-dompdf` (PDF) |
| **Aplikasi Mobile** | Flutter (Dart SDK ^3.11), mendukung Android, iOS, Web, Windows, macOS |
| **Automasi/Chatbot** | n8n (workflow "TaniBot_Chat_Workflow") |
| **Containerization** | Docker & Docker Compose |
| **Testing** | PHPUnit (Feature & Unit test) |

### Arsitektur Deployment (Production)

```
                    ┌─────────────────────┐
                    │   Client (Mobile /   │
                    │   Web Browser)       │
                    └──────────┬───────────┘
                               │ HTTPS
                    ┌──────────▼───────────┐
                    │  App Container        │
                    │  (Nginx + PHP-FPM +    │
                    │   Laravel 13)          │
                    └───┬───────────────┬────┘
                        │               │
              ┌─────────▼───┐   ┌───────▼──────┐
              │  MySQL 8.0   │   │  Redis 7      │
              │  (Database)  │   │  (Cache)      │
              └──────────────┘   └───────────────┘
```

Stack production didefinisikan di `docker-compose.yml` (3 service: `app`, `db`, `cache`), masing-masing dengan health check dan volume persisten untuk storage, log, dan data database.

---

## 6. Instalasi Teknis

### 6.1 Backend (Laravel API)

**Prasyarat:**
- PHP >= 8.3
- Composer
- Node.js 18+ & npm (untuk build asset Vite)
- SQLite (dev) atau MySQL 8.0 (production)

**Langkah instalasi (development lokal):**

```bash
# 1. Clone repository
git clone https://github.com/ghea-creator/SIMHPSK-kelompok-3.git
cd SIMHPSK-kelompok-3

# 2. Install dependency PHP
composer install

# 3. Install dependency Node.js (untuk asset)
npm install

# 4. Siapkan environment
cp .env.example .env
php artisan key:generate

# 5. Jalankan migrasi database (default: SQLite)
php artisan migrate

# 6. (Opsional) Seed data contoh
php artisan db:seed

# 7. Jalankan server development
php artisan serve
```

Aplikasi dapat diakses di `http://localhost:8000`.

**Menjalankan test:**
```bash
php artisan test
# atau
vendor/bin/phpunit --testdox
```

### 6.2 Deployment via Docker (Production)

**Prasyarat:** Docker & Docker Compose terpasang.

```bash
# 1. Siapkan environment production
cp .env.example .env.production
# edit .env.production: isi APP_KEY, DB_PASSWORD, REDIS_PASSWORD, dll.

# 2. Build & jalankan seluruh stack (app + MySQL + Redis)
docker compose up --build -d

# 3. Jalankan migrasi di dalam container
docker compose exec app php artisan migrate --force
```

Aplikasi akan tersedia di port 80/443 sesuai konfigurasi `docker-compose.yml`. Detail lebih lanjut ada di `DOCKER_DEPLOYMENT.md` dan `DOCKER_PRODUCTION_GUIDE.md` pada repo ini.

### 6.3 Aplikasi Mobile (Flutter)

**Prasyarat:**
- Flutter SDK (Dart ^3.11)
- Android Studio / Xcode (sesuai target platform)

```bash
cd mobile_app

# 1. Install dependency
flutter pub get

# 2. Sesuaikan URL API backend
# edit file konfigurasi endpoint API di lib/ agar mengarah ke
# URL backend Laravel yang sudah berjalan (lokal atau production)

# 3. Jalankan aplikasi
flutter run
```

Mendukung target: Android, iOS, Web, Windows, macOS (folder tersedia untuk masing-masing platform).

### 6.4 Integrasi Chatbot (n8n) — Opsional

Workflow chatbot (`TaniBot_Chat_Workflow.json`) tersedia di folder `n8n/`. Import file tersebut ke instance n8n untuk mengaktifkan fitur chatbot. Panduan lengkap ada di `N8N_INTEGRATION_GUIDE.md` dan `N8N_QUICK_SETUP.md`.

---

## 7. Struktur Proyek

```
SIMHPSK-kelompok-3/
├── app/                    # Kode aplikasi Laravel (Controller, Model)
│   └── Http/Controllers/   # AuthController, SeasonController, HarvestController,
│                            # StockController, SaleController, CostController,
│                            # ReportController, SettingController, dst.
├── database/                # Migration, factory, seeder
├── docker/                  # Konfigurasi Nginx, PHP, MySQL, supervisor
├── mobile_app/               # Aplikasi Flutter (Android/iOS/Web/Windows/macOS)
├── n8n/                      # Workflow chatbot n8n
├── routes/api.php            # Definisi seluruh endpoint API
├── tests/Feature/            # Automated test (PHPUnit)
├── docker-compose.yml         # Stack production (App + MySQL + Redis)
├── Dockerfile                 # Image aplikasi Laravel
├── composer.json              # Dependency PHP
└── API_DOCUMENTATION.md       # Dokumentasi lengkap seluruh endpoint API
```

Dokumentasi tambahan yang tersedia di root repo: `API_DOCUMENTATION.md`, `API_GUIDE.md`, `DEPLOYMENT_GUIDE.md`, `N8N_INTEGRATION_GUIDE.md`, `EXPORT_GUIDE.md`.

-
## Lisensi

Proyek ini dibuat untuk keperluan tugas akademik (UAS Rekayasa Sistem Informasi).


<img width="610" height="1356" alt="image" src="https://github.com/user-attachments/assets/c5530d42-6c79-4df6-8a31-002389fdc470" />
<img width="610" height="1356" alt="image" src="https://github.com/user-attachments/assets/f2211bc4-3af1-40c7-ae9d-03e12a1668c7" />

