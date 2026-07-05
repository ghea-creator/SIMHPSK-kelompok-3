# ⚙️ Setup & Installation Guide

Panduan lengkap untuk menginstall dan menjalankan sistem PresensiHub dengan fitur QR Code.

---

## 📋 Prerequisites

Sebelum memulai, pastikan sudah terinstall:

- **Node.js** (v14 atau lebih baru)
  - Download dari: https://nodejs.org/
  - Verify: `node -v` dan `npm -v`

- **MySQL** (v5.7 atau lebih baru) atau **MariaDB**
  - Bisa menggunakan **Laragon**, **XAMPP**, atau instalasi lokal
  - Verify: `mysql --version`

- **Git** (opsional, untuk clone repository)
  - Download dari: https://git-scm.com/

---

## 🚀 Instalasi Langkah demi Langkah

### Step 1: Persiapan Database

**Pastikan MySQL/MariaDB berjalan:**

```bash
# Untuk Laragon (Windows)
# Buka Laragon, klik tombol "Start All"

# Untuk XAMPP (Windows)
# Buka XAMPP Control Panel, start Apache dan MySQL

# Untuk Linux/Mac
sudo service mysql start
```

**Verify database koneksi:**
```bash
mysql -u root -p
# Masukkan password (kosong jika default)
# Jika berhasil, keluar dengan: exit
```

---

### Step 2: Clone atau Download Project

**Option A: Clone dari Git (jika menggunakan Git)**
```bash
cd c:\laragon\www  # atau direktori web lainnya
git clone https://github.com/your-repo/backend-absensi.git
cd backend-absensi
```

**Option B: Download ZIP**
1. Download project dari repository
2. Extract ke `c:\laragon\www\backend-absensi`
3. Buka terminal di folder tersebut

---

### Step 3: Install Backend Dependencies

```bash
# Navigate ke folder backend
cd c:\laragon\www\backend-absensi

# Install npm packages
npm install
```

**Packages yang akan diinstall:**
- express: Web framework
- mysql2: Database driver
- jsonwebtoken: JWT authentication
- bcryptjs: Password hashing
- cors: Cross-origin resource sharing
- qrcode: QR code generation
- axios: HTTP client

---

### Step 4: Konfigurasi Database

**File: `config/db.js`**

Pastikan konfigurasi sudah sesuai (default sudah benar untuk Laragon):

```javascript
const mysql = require('mysql2');

const db = mysql.createConnection({
    host: 'localhost',      // Database host
    user: 'root',          // Database user
    password: '',          // Database password (kosong untuk Laragon)
    database: 'absensi_qr' // Database name (akan dibuat otomatis)
});

db.connect((err) => {
    if (err) {
        console.log('Koneksi gagal:', err);
    } else {
        console.log('Database terkoneksi');
    }
});

module.exports = db;
```

**Jika menggunakan password:**
```javascript
password: 'your_mysql_password',
```

---

### Step 5: Jalankan Backend Server

```bash
# Dari folder backend-absensi
node index.js
```

**Output yang diharapkan:**
```
🌱 Seeded default users with pegawai: admin/123456 & budi/123456
🌱 Seeded default divisions
✅ Database initialization completed successfully!
Server jalan di http://localhost:5000 ✅
```

**Berarti backend berhasil dijalankan!** ✅

---

### Step 6: Install Frontend Dependencies

**Buka terminal baru (jangan tutup terminal backend):**

```bash
# Navigate ke folder frontend
cd c:\laragon\www\backend-absensi\frontend-absensi

# Install npm packages
npm install
```

---

### Step 7: Jalankan Frontend Development Server

```bash
# Dari folder frontend-absensi
npm run dev
```

**Output yang diharapkan:**
```
  VITE v... ready in ... ms

  ➜  Local:   http://localhost:5173/
  ➜  press h to show help
```

**Frontend sudah siap di:** `http://localhost:5173` ✅

---

### Step 8: Akses Aplikasi

**Buka browser dan akses:**
```
http://localhost:5173
```

**Login dengan credentials default:**
- **Username:** `admin`
- **Password:** `123456`

---

## 🔧 Troubleshooting

### Error: "Database not initialized"

**Solusi:**
1. Pastikan MySQL sudah berjalan
2. Pastikan tidak ada folder `node_modules` yang corrupt
3. Delete folder `node_modules` dan jalankan `npm install` lagi
4. Restart backend server

```bash
rm -r node_modules
npm install
node index.js
```

---

### Error: "ECONNREFUSED - connect ECONNREFUSED 127.0.0.1:5000"

**Artinya:** Backend tidak berjalan

**Solusi:**
1. Pastikan backend server sedang berjalan di terminal terpisah
2. Pastikan backend berjalan di port 5000
3. Jika port sudah terpakai, ganti port di `index.js`:
   ```javascript
   app.listen(5001, () => {  // Change from 5000 to 5001
     console.log("Server jalan di http://localhost:5001");
   });
   ```

---

### Error: "npm: command not found"

**Artinya:** Node.js belum terinstall atau belum di PATH

**Solusi:**
1. Download Node.js dari https://nodejs.org/
2. Install dengan opsi "Add to PATH"
3. Restart terminal
4. Verify: `node -v` dan `npm -v`

---

### Error: "Could not connect to MySQL"

**Solusi:**
1. Pastikan MySQL sudah berjalan
2. Check credentials di `config/db.js`
3. Pastikan database user `root` tidak punya password (atau update config)
4. Untuk Laragon:
   - Klik tombol MySQL di Laragon
   - Klik "MySQL" → "MySQL" untuk memastikan running

---

### Error: "Port 5173 already in use"

**Solusi:**
1. Gunakan port lain:
   ```bash
   npm run dev -- --port 3000
   ```
2. Atau kill process yang menggunakan port 5173:
   ```bash
   # Windows
   netstat -ano | findstr :5173
   taskkill /PID {PID} /F
   
   # Linux/Mac
   lsof -ti:5173 | xargs kill -9
   ```

---

## 📁 Project Structure

```
backend-absensi/
├── index.js                 # Main backend server
├── package.json            # Backend dependencies
├── config/
│   └── db.js              # Database configuration
├── controllers/            # (Empty, logic in index.js)
├── routers/                # (Empty, routes in index.js)
├── frontend-absensi/       # React frontend
│   ├── src/
│   │   ├── App.jsx         # Main React component
│   │   ├── App.css         # Styles
│   │   ├── index.css       # Global styles
│   │   └── main.jsx        # React entry point
│   ├── public/             # Static assets
│   ├── package.json        # Frontend dependencies
│   ├── vite.config.js      # Vite configuration
│   └── index.html          # HTML template
├── FITUR_BARU.md           # Feature documentation
├── QUICK_START.md          # Quick start guide
├── API_REFERENCE.md        # API endpoints reference
└── IMPLEMENTATION_SUMMARY.md # Implementation details
```

---

## 🎯 Verify Installation

### Checklist

- [ ] Backend server berjalan di `http://localhost:5000`
- [ ] Frontend server berjalan di `http://localhost:5173`
- [ ] Bisa login dengan username: `admin`, password: `123456`
- [ ] Database `absensi_qr` sudah dibuat
- [ ] Table `qr_codes` sudah dibuat
- [ ] Bisa akses tab "🎫 QR Code User" sebagai admin
- [ ] Bisa akses tab "➕ Buat User Baru" sebagai admin
- [ ] Bisa akses tab "🎫 Scan QR Admin" sebagai user

---

## 🚀 Deployment (Production)

### Preparation Checklist

- [ ] Database backup sudah dibuat
- [ ] Environment variables sudah diset
- [ ] JWT secret sudah diganti (jangan gunakan 'SECRET_KEY')
- [ ] CORS origin sudah dikonfigurasi
- [ ] HTTPS/SSL sudah setup
- [ ] Rate limiting sudah activated
- [ ] Logging sudah configured
- [ ] Error handling sudah tested

### Production Configuration

**File: `index.js`**

Ubah secret key:
```javascript
const SECRET_KEY = process.env.JWT_SECRET || "your-very-secure-secret-key";
```

Setup environment:
```bash
# .env file
JWT_SECRET=your-very-secure-secret-key
DB_HOST=production-db-host
DB_USER=production_db_user
DB_PASSWORD=production_db_password
DB_NAME=absensi_qr_prod
NODE_ENV=production
```

Update database config:
```javascript
const db = await mysql.createConnection({
  host: process.env.DB_HOST || "localhost",
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD || "",
  database: process.env.DB_NAME || "absensi_qr",
});
```

---

## 🔐 Security Best Practices

1. **Change default admin password immediately**
   ```sql
   UPDATE users SET password = HASH('new_password') WHERE username = 'admin';
   ```

2. **Secure JWT Secret**
   - Don't use default 'SECRET_KEY'
   - Use strong random string (32+ characters)
   - Store in environment variables

3. **Database Security**
   - Remove default root password
   - Create separate DB user with limited privileges
   - Use strong password for DB user

4. **SSL/HTTPS**
   - Enable SSL certificate
   - Redirect HTTP to HTTPS
   - Set secure cookie flags

5. **Firewall Rules**
   - Only allow trusted IPs to access backend
   - Block direct database access from internet
   - Use VPN for remote access

---

## 📊 Monitoring

### Check Logs

**Backend logs:**
```bash
# Real-time logs
node index.js

# With logging to file
node index.js > logs/server.log 2>&1
```

**Database logs:**
```bash
# MySQL error log location
# Windows: C:\MySQL\data\error.log
# Linux: /var/log/mysql/error.log
```

### Performance Monitoring

**Check database size:**
```sql
SELECT 
  table_name,
  ROUND(((data_length + index_length) / 1024 / 1024), 2) AS size_mb
FROM information_schema.tables
WHERE table_schema = 'absensi_qr'
ORDER BY size_mb DESC;
```

**Check slow queries:**
```sql
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2; -- queries longer than 2 seconds
```

---

## 🆘 Getting Help

**Jika ada masalah:**

1. **Check logs:**
   - Backend logs di terminal
   - Browser console (F12 → Console)
   - Network tab (F12 → Network)

2. **Verify connections:**
   - Backend running: `http://localhost:5000`
   - Frontend running: `http://localhost:5173`
   - Database connected: `mysql -u root`

3. **Check documentation:**
   - [FITUR_BARU.md](FITUR_BARU.md) - Feature details
   - [QUICK_START.md](QUICK_START.md) - Quick guide
   - [API_REFERENCE.md](API_REFERENCE.md) - API endpoints

4. **Common issues:**
   - Port already in use → Change port or kill process
   - Database not found → Check MySQL is running
   - Module not found → Run `npm install` again
   - CORS error → Check frontend URL in backend

---

## 📝 Notes

- Default database user: `root` (no password)
- Default database: `absensi_qr` (created automatically)
- Default admin: `admin` / `123456`
- Backend port: `5000`
- Frontend port: `5173`
- JWT expiration: 1 hour
- Bcrypt salt rounds: 10

---

**Setup Complete! 🎉**

Sekarang Anda bisa mulai menggunakan sistem PresensiHub dengan fitur QR Code!

Untuk panduan penggunaan, baca: [QUICK_START.md](QUICK_START.md)
