// =======================
// IMPORT MODULE
// =======================
console.log("🔧 index.js file is loading...");
const express = require("express");
const mysql = require("mysql2/promise");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const cors = require("cors");
const axios = require("axios");

const app = express();

// =======================
// MIDDLEWARE (WAJIB DI ATAS)
// =======================
app.use(cors());
app.use(express.json());

// =======================
// SECRET JWT
// =======================
const SECRET_KEY = "SECRET_KEY";

// =======================
// 🔥 KONEKSI DATABASE & INISIALISASI OTOMATIS
// =======================
let db = null;
let dbInitialized = false;

async function getDatabase() {
  if (!db) {
    throw new Error("Database not initialized. Please wait...");
  }
  return db;
}

// Function untuk inisialisasi database
async function initializeDatabase() {
  try {
    // 1. Hubungkan ke MySQL Server terlebih dahulu (tanpa nama DB) untuk memastikan DB ada
    const initConn = await mysql.createConnection({
      host: "localhost",
      user: "root",
      password: "",
    });

    // 2. Buat database absensi_qr jika belum ada
    await initConn.query("CREATE DATABASE IF NOT EXISTS absensi_qr");
    await initConn.end();

    // 3. Hubungkan ke database absensi_qr yang sebenarnya
    db = await mysql.createConnection({
      host: "localhost",
      user: "root",
      password: "",
      database: "absensi_qr",
    });

    console.log("Database absensi_qr terkoneksi 🔥");

    // 4. Buat tabel-tabel jika belum ada
    // Tabel Users
    await db.query(`
      CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(255) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        role VARCHAR(50) NOT NULL DEFAULT 'user'
      )
    `);

    // Migrasi: Tambah kolom role jika tabel users sudah ada sebelumnya tanpa kolom tersebut
    try {
      await db.query("ALTER TABLE users ADD COLUMN role VARCHAR(50) NOT NULL DEFAULT 'user'");
      console.log("Column 'role' successfully migrated to table users ⚙️");
    } catch (e) {
      // Kolom role sudah ada, aman untuk dilewati
    }

    try {
      await db.query("ALTER TABLE users ADD COLUMN pegawai_id INT NULL");
      console.log("Column 'pegawai_id' successfully migrated to table users ⚙️");
    } catch (e) {}

    try {
      await db.query("ALTER TABLE users ADD COLUMN password_raw VARCHAR(255) NULL");
      console.log("Column 'password_raw' successfully migrated to table users ⚙️");
    } catch (e) {}

    // Tabel Divisi
    await db.query(`
      CREATE TABLE IF NOT EXISTS divisi (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nama_divisi VARCHAR(255) NOT NULL
      )
    `);

    // Tabel Pegawai
    await db.query(`
      CREATE TABLE IF NOT EXISTS pegawai (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nama VARCHAR(255) NOT NULL,
        divisi_id INT,
        jabatan VARCHAR(255) NOT NULL,
        FOREIGN KEY (divisi_id) REFERENCES divisi(id) ON DELETE SET NULL
      )
    `);

    // Tabel Absensi
    await db.query(`
      CREATE TABLE IF NOT EXISTS absensi (
        id INT AUTO_INCREMENT PRIMARY KEY,
        pegawai_id INT,
        tanggal DATE NOT NULL,
        jam_masuk TIME,
        jam_keluar TIME,
        status VARCHAR(50),
        FOREIGN KEY (pegawai_id) REFERENCES pegawai(id) ON DELETE CASCADE
      )
    `);

    // Tabel Cuti Tambahan
    await db.query(`
      CREATE TABLE IF NOT EXISTS cuti_tambahan (
        id INT AUTO_INCREMENT PRIMARY KEY,
        pegawai_id INT NOT NULL,
        tanggal_pengajuan DATE NOT NULL,
        alasan TEXT,
        durasi_hari INT NOT NULL,
        status VARCHAR(50) NOT NULL DEFAULT 'Pending',
        FOREIGN KEY (pegawai_id) REFERENCES pegawai(id) ON DELETE CASCADE
      )
    `);

    // Tabel QR Code untuk Absensi User
    await db.query(`
      CREATE TABLE IF NOT EXISTS qr_codes (
        id INT AUTO_INCREMENT PRIMARY KEY,
        pegawai_id INT NOT NULL,
        qr_code VARCHAR(255) NOT NULL UNIQUE,
        tanggal_dibuat TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        tanggal_berlaku DATE NOT NULL,
        tanggal_kadaluarsa DATETIME,
        status ENUM('active', 'used', 'expired', 'deleted') DEFAULT 'active',
        digunakan_pada DATETIME,
        FOREIGN KEY (pegawai_id) REFERENCES pegawai(id) ON DELETE CASCADE,
        INDEX idx_qr_code (qr_code),
        INDEX idx_pegawai_id (pegawai_id),
        INDEX idx_status (status)
      )
    `);

    // ✅ Tabel Settings Jam Kerja
    await db.query(`
      CREATE TABLE IF NOT EXISTS settings_kerja (
        id INT AUTO_INCREMENT PRIMARY KEY,
        jam_masuk_awal TIME DEFAULT '07:00',
        jam_masuk_akhir TIME DEFAULT '09:00',
        jam_keluar_awal TIME DEFAULT '16:00',
        jam_keluar_akhir TIME DEFAULT '17:00',
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `);

    // Seed default settings jika kosong
    const [settingsCheck] = await db.query("SELECT COUNT(*) as count FROM settings_kerja");
    if (settingsCheck[0].count === 0) {
      await db.query(
        "INSERT INTO settings_kerja (jam_masuk_awal, jam_masuk_akhir, jam_keluar_awal, jam_keluar_akhir) VALUES ('07:00', '09:00', '16:00', '17:00')"
      );
      console.log("Default work hours settings created ⏰");
    }

    // Migrasi kolom tambahan tabel absensi
    try {
      await db.query("ALTER TABLE absensi ADD COLUMN alasan TEXT NULL");
      console.log("Column 'alasan' added to absensi ⚙️");
    } catch (e) {}
    try {
      await db.query("ALTER TABLE absensi ADD COLUMN foto_bukti LONGTEXT NULL");
      console.log("Column 'foto_bukti' added to absensi ⚙️");
    } catch (e) {}
    try {
      await db.query("ALTER TABLE absensi ADD COLUMN keterangan_jam VARCHAR(100) NULL");
      console.log("Column 'keterangan_jam' added to absensi ⚙️");
    } catch (e) {}
    try {
      await db.query("ALTER TABLE absensi ADD COLUMN is_lembur TINYINT(1) DEFAULT 0");
      console.log("Column 'is_lembur' added to absensi ⚙️");
    } catch (e) {}

    // Migrasi kolom tambahan tabel pegawai
    try {
      await db.query("ALTER TABLE pegawai ADD COLUMN foto LONGTEXT NULL");
      console.log("Column 'foto' added to pegawai ⚙️");
    } catch (e) {}

    // Migrasi kolom biodata
    try {
      await db.query("ALTER TABLE pegawai ADD COLUMN no_telepon VARCHAR(20) NULL");
      console.log("Column 'no_telepon' added to pegawai ⚙️");
    } catch (e) {}
    try {
      await db.query("ALTER TABLE pegawai ADD COLUMN alamat TEXT NULL");
      console.log("Column 'alamat' added to pegawai ⚙️");
    } catch (e) {}
    try {
      await db.query("ALTER TABLE pegawai ADD COLUMN tanggal_lahir DATE NULL");
      console.log("Column 'tanggal_lahir' added to pegawai ⚙️");
    } catch (e) {}
    try {
      await db.query("ALTER TABLE pegawai ADD COLUMN jenis_kelamin VARCHAR(20) NULL");
      console.log("Column 'jenis_kelamin' added to pegawai ⚙️");
    } catch (e) {}

    // Migrasi kolom tambahan tabel cuti_tambahan
    try {
      await db.query("ALTER TABLE cuti_tambahan ADD COLUMN tanggal_mulai DATE NULL");
      console.log("Column 'tanggal_mulai' added to cuti_tambahan ⚙️");
    } catch (e) {}
    try {
      await db.query("ALTER TABLE cuti_tambahan ADD COLUMN tanggal_selesai DATE NULL");
      console.log("Column 'tanggal_selesai' added to cuti_tambahan ⚙️");
    } catch (e) {}
    try {
      await db.query("ALTER TABLE cuti_tambahan ADD COLUMN keperluan VARCHAR(255) NULL");
      console.log("Column 'keperluan' added to cuti_tambahan ⚙️");
    } catch (e) {}
    try {
      await db.query("ALTER TABLE cuti_tambahan ADD COLUMN foto_bukti LONGTEXT NULL");
      console.log("Column 'foto_bukti' added to cuti_tambahan ⚙️");
    } catch (e) {}
    // Notif pop-up user untuk status cuti
    try {
      await db.query("ALTER TABLE cuti_tambahan ADD COLUMN notified_status VARCHAR(50) NULL");
      console.log("Column 'notified_status' added to cuti_tambahan ⚙️");
    } catch (e) {}
    try {
      await db.query("ALTER TABLE cuti_tambahan ADD COLUMN notified_at DATETIME NULL");
      console.log("Column 'notified_at' added to cuti_tambahan ⚙️");
    } catch (e) {}


    // 🔄 Populate existing Hadir records with keterangan_jam if NULL
    try {
      const [workSettings] = await db.query("SELECT jam_masuk_akhir, jam_keluar_akhir FROM settings_kerja LIMIT 1");
      if (workSettings.length > 0) {
        const settings = workSettings[0];
        
        // Get all Hadir records with NULL keterangan_jam
        const [nullRecords] = await db.query(
          "SELECT id, jam_masuk, jam_keluar FROM absensi WHERE status = 'Hadir' AND keterangan_jam IS NULL"
        );
        
        let terlambatCount = 0, lemburCount = 0;
        
        for (const record of nullRecords) {
          let keteranganJam = null;
          
          // Priority 1: Check for Terlambat (late check-in)
          if (record.jam_masuk && record.jam_masuk > settings.jam_masuk_akhir) {
            keteranganJam = 'Terlambat';
            terlambatCount++;
          }
          // Priority 2: Check for Lembur (overtime check-out) - only if no Terlambat
          else if (record.jam_keluar && record.jam_keluar > settings.jam_keluar_akhir) {
            keteranganJam = 'Lembur';
            lemburCount++;
          }
          
          if (keteranganJam) {
            await db.query(
              "UPDATE absensi SET keterangan_jam = ? WHERE id = ?",
              [keteranganJam, record.id]
            );
          }
        }
        
        if (terlambatCount > 0 || lemburCount > 0) {
          console.log(`📊 Populated ${terlambatCount} Terlambat & ${lemburCount} Lembur records ⏱️`);
        }
      }
    } catch (e) {
      console.log("Migration for keterangan_jam completed or already done ✓");
    }

    // 🔄 Populate is_lembur for existing records
    try {
      const [workSettings2] = await db.query("SELECT jam_keluar_akhir FROM settings_kerja LIMIT 1");
      if (workSettings2.length > 0) {
        const jamKeluar = workSettings2[0].jam_keluar_akhir;
        const [result] = await db.query(
          `UPDATE absensi SET is_lembur = 1
           WHERE status = 'Hadir'
             AND jam_keluar IS NOT NULL
             AND TIME(jam_keluar) > TIME(?)
             AND (is_lembur IS NULL OR is_lembur = 0)`,
          [jamKeluar]
        );
        if (result.affectedRows > 0) {
          console.log(`📊 Marked ${result.affectedRows} records as is_lembur=1 ⏰`);
        }
      }
    } catch (e) {
      console.log("Migration for is_lembur completed or already done ✓");
    }

    console.log("Struktur tabel siap & terverifikasi 📁");

    // 5. Seeding Data Default
    // A. Seed Admin user (TANPA masuk tabel pegawai - admin hanya untuk login)
    const [adminCheck] = await db.query("SELECT COUNT(*) as count FROM users WHERE username = 'admin' AND role = 'admin'");
    if (adminCheck[0].count === 0) {
      const adminHash = await bcrypt.hash("123456", 10);
      // Admin tidak punya pegawai_id (NULL) karena admin bukan pegawai biasa
      await db.query(
        "INSERT INTO users (username, password, password_raw, role, pegawai_id) VALUES (?, ?, ?, ?, ?)", 
        ["admin", adminHash, "123456", "admin", null]
      );
      console.log("🌱 Seeded default admin: admin/123456");
    }

    // B. Seed Divisi jika kosong
    const [divisiCount] = await db.query("SELECT COUNT(*) as count FROM divisi");
    if (divisiCount[0].count === 0) {
      await db.query("INSERT INTO divisi (nama_divisi) VALUES ('IT'), ('HRD'), ('Finance'), ('Marketing')");
      console.log("🌱 Seeded default divisions");
    }

    console.log("✅ Database initialization completed successfully!");
    dbInitialized = true;
    console.log("✅ dbInitialized flag set to true");
    return true;
  } catch (err) {
    console.error("❌ DB Error & Inisialisasi Gagal:");
    console.error("Error message:", err?.message || err);
    console.error("Full error:", err);
    if (err?.code) console.error("Error code:", err.code);
    if (err?.errno) console.error("Error errno:", err.errno);
    return false;
  }
}

// =======================
// 🔐 MIDDLEWARE CECK DB READY
// =======================
function checkDbReady(req, res, next) {
  console.log('🔍 checkDbReady middleware called, db is:', db ? '✅ READY' : '❌ NOT READY');
  if (!db) {
    console.log('❌ DB NOT READY - denying request');
    return res.status(503).json({ message: "Database belum siap. Coba lagi dalam beberapa saat." });
  }
  console.log('✅ DB READY - continuing request');
  next();
}

// =======================
// 🔐 MIDDLEWARE JWT
// =======================
function verifyToken(req, res, next) {
  const bearerHeader = req.headers["authorization"];

  if (!bearerHeader) {
    return res.status(403).json({ message: "Token tidak ada" });
  }

  const token = bearerHeader.split(" ")[1];

  jwt.verify(token, SECRET_KEY, (err, decoded) => {
    if (err) {
      return res.status(403).json({ message: "Token tidak valid" });
    }

    req.user = decoded;
    next();
  });
}

// =======================
// 🏠 ROUTE HOME
// =======================
app.get("/", (req, res) => {
  res.send("Backend Absensi JWT 🔥");
});

// Endpoint Ketidakhadiran
console.log("DEBUG: Registering /absence-list endpoint");
app.get("/absence-list", verifyToken, checkDbReady, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({message: "Admin only"});
    }
    const queryDate = req.query.tanggal || new Date().toISOString().split('T')[0];
    const [allPegawai] = await db.query("SELECT id, nama, jabatan, divisi_id, foto FROM pegawai ORDER BY nama ASC");
    const [hadir] = await db.query("SELECT DISTINCT pegawai_id FROM absensi WHERE tanggal = ?", [queryDate]);
    const hadirIds = new Set(hadir.map(h => h.pegawai_id));
    const [cutiDiajukan] = await db.query("SELECT DISTINCT pegawai_id FROM cuti_tambahan WHERE status = 'Disetujui' AND tanggal_mulai <= ? AND tanggal_selesai >= ?", [queryDate, queryDate]);
    const cutiIds = new Set(cutiDiajukan.map(c => c.pegawai_id));
    const tidakHadir = allPegawai.filter(p => !hadirIds.has(p.id) && !cutiIds.has(p.id)).map(p => ({id: p.id, nama: p.nama, jabatan: p.jabatan, divisi_id: p.divisi_id, foto: p.foto, status: 'Tidak Hadir'}));
    res.json({tanggal: queryDate, total_tidak_hadir: tidakHadir.length, data: tidakHadir});
  } catch (err) {
    console.error("Error:", err);
    res.status(500).json({message: err.message});
  }
});

// =======================
// 📊 REKAP HARIAN PRESENSI (ADMIN)
// =======================
app.get("/rekap-harian", verifyToken, checkDbReady, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: "Admin only" });
    }

    const now = new Date();
    const jakartaNow = new Date(now.toLocaleString('en-US', { timeZone: 'Asia/Jakarta' }));
    const todayStr = `${jakartaNow.getFullYear()}-${String(jakartaNow.getMonth()+1).padStart(2,'0')}-${String(jakartaNow.getDate()).padStart(2,'0')}`;
    const currentTimeStr = `${String(jakartaNow.getHours()).padStart(2,'0')}:${String(jakartaNow.getMinutes()).padStart(2,'0')}:00`;

    const queryDate = req.query.tanggal || todayStr;

    // Check Future Date
    if (queryDate > todayStr) {
      return res.json({
        tanggal: queryDate,
        is_holiday: false,
        rekap: {
          total_pegawai: 0,
          hadir: 0,
          terlambat: 0,
          lembur: 0,
          izin: 0,
          sakit: 0,
          alpa: 0,
          cuti_tambahan_disetujui: 0,
        }
      });
    }

    // Check if weekend or holiday
    const d = new Date(queryDate + 'T00:00:00');
    const dayOfWeek = d.getDay();
    let isHoliday = false;
    let holidayName = "";

    if (dayOfWeek === 0 || dayOfWeek === 6) {
      isHoliday = true;
      holidayName = "Akhir Pekan";
    } else {
      // Check Holiday
      try {
        const year = d.getFullYear();
        const holidayResponse = await axios.get(`https://api-hari-libur.vercel.app/api?year=${year}`, { timeout: 3000 });
        if (holidayResponse.data && holidayResponse.data.status === "success") {
          const holiday = holidayResponse.data.data.find(h => h.date === queryDate);
          if (holiday) {
            isHoliday = true;
            holidayName = holiday.description;
          }
        }
      } catch (apiErr) {
        console.error("Gagal mengambil data libur nasional untuk rekap:", apiErr.message);
      }
    }

    if (isHoliday) {
      return res.json({
        tanggal: queryDate,
        is_holiday: true,
        holiday_name: holidayName,
        rekap: {
          total_pegawai: 0,
          hadir: 0,
          terlambat: 0,
          lembur: 0,
          izin: 0,
          sakit: 0,
          alpa: 0,
          cuti_tambahan_disetujui: 0,
        }
      });
    }

    // Semua pegawai
    const [allPegawai] = await db.query(
      "SELECT id FROM pegawai"
    );

    const pegawaiIds = allPegawai.map(p => p.id);

    // Hadir (mengalahkan status lain)
    const [hadirRows] = await db.query(
      "SELECT DISTINCT pegawai_id FROM absensi WHERE tanggal = ? AND status = 'Hadir'",
      [queryDate]
    );
    const hadirSet = new Set(hadirRows.map(r => r.pegawai_id));

    // Rekap status absensi yang bukan Hadir
    const [izinSakitRows] = await db.query(
      "SELECT pegawai_id, status FROM absensi WHERE tanggal = ? AND status IN ('Izin','Sakit')",
      [queryDate]
    );
    const izinSet = new Set(izinSakitRows.filter(r => r.status === 'Izin').map(r => r.pegawai_id));
    const sakitSet = new Set(izinSakitRows.filter(r => r.status === 'Sakit').map(r => r.pegawai_id));

    // Terlambat & Lembur (jika keterangan_jam terisi)
    const [terlambatRows] = await db.query(
      "SELECT COUNT(*) as jumlah FROM absensi WHERE tanggal = ? AND status = 'Hadir' AND keterangan_jam = 'Terlambat'",
      [queryDate]
    );
    const [lemburRows] = await db.query(
      "SELECT COUNT(*) as jumlah FROM absensi WHERE tanggal = ? AND status = 'Hadir' AND keterangan_jam = 'Lembur'",
      [queryDate]
    );

    // Cuti Tambahan Disetujui yang rentangnya mencakup tanggal
    const [cutiRows] = await db.query(
      "SELECT DISTINCT pegawai_id FROM cuti_tambahan WHERE LOWER(status) = 'disetujui' AND tanggal_mulai <= ? AND tanggal_selesai >= ?",
      [queryDate, queryDate]
    );
    const cutiSet = new Set(cutiRows.map(r => r.pegawai_id));

    // Ambil jumlah untuk Hadir
    const [hadirCountRows] = await db.query(
      "SELECT COUNT(DISTINCT pegawai_id) as jumlah FROM absensi WHERE tanggal = ? AND status = 'Hadir'",
      [queryDate]
    );

    // Fetch work settings for jam_masuk_akhir comparison
    const [workSettingsRows] = await db.query('SELECT * FROM settings_kerja LIMIT 1');
    const settings = workSettingsRows[0];
    const jamMasukAkhir = settings ? String(settings.jam_masuk_akhir) : '10:00:00';
    const normalizeT = (t) => t && t.length === 5 ? t + ':00' : (t || '10:00:00');
    const jamMasukAkhirNorm = normalizeT(jamMasukAkhir);

    const isPastOrClosed = (queryDate < todayStr) || 
                           (queryDate === todayStr && currentTimeStr >= jamMasukAkhirNorm);

    // Dynamic Alpa calculation:
    let dynamicAlpaCount = 0;
    if (isPastOrClosed) {
      pegawaiIds.forEach(id => {
        if (hadirSet.has(id)) return;
        if (izinSet.has(id)) return;
        if (sakitSet.has(id)) return;
        if (cutiSet.has(id)) return;
        dynamicAlpaCount++;
      });
    }

    const rekap = {
      total_pegawai: pegawaiIds.length,
      hadir: hadirCountRows?.[0]?.jumlah || 0,
      terlambat: terlambatRows?.[0]?.jumlah || 0,
      lembur: lemburRows?.[0]?.jumlah || 0,
      izin: izinSet.size,
      sakit: sakitSet.size,
      alpa: dynamicAlpaCount,
      cuti_tambahan_disetujui: cutiSet.size,
    };

    return res.json({
      tanggal: queryDate,
      rekap,
    });
  } catch (err) {
    console.error("Error /rekap-harian:", err);
    res.status(500).json({ message: err.message });
  }
});



// =======================
// � QUERY HELPER FUNCTION
// =======================
async function queryDatabase(sql, params = []) {
  if (!db) {
    throw new Error("Database not initialized");
  }
  try {
    const [rows, fields] = await db.query(sql, params);
    return rows;
  } catch (err) {
    console.error('Database query error:', err.message);
    throw err;
  }
}

// =======================
// �🔑 REGISTER (BIAR GA SALAH HASH)
// =======================
// =======================
// 🔑 REGISTER (BIAR GA SALAH HASH)
// =======================
app.post("/register", async (req, res) => {
  try {
    const database = await getDatabase();
    let { username, password } = req.body;
    if (username) username = username.trim();

    const hash = await bcrypt.hash(password, 10);

    await database.query(
      "INSERT INTO users (username, password) VALUES (?, ?)",
      [username, hash]
    );

    res.json({ message: "Register berhasil" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});


// =======================
// 🔑 LOGIN
// =======================

app.post('/login', async (req, res) => {

    try {
        const database = await getDatabase();
        console.log('🔐 Login endpoint - db retrieved');
        
        let { username, password } = req.body;
        if (username) username = username.trim();
        console.log('Login attempt for:', username);

        const [rows] = await database.query(
            'SELECT * FROM users WHERE username = ?',
            [username]
        );
        
        console.log('Query successful, users found:', rows.length);

        if (rows.length === 0) {
            return res.status(401).json({
                message: 'User tidak ditemukan'
            });
        }

        const user = rows[0];
        console.log('User found:', user.username);

        const validPassword = await bcrypt.compare(password, user.password);

        if (!validPassword) {
            return res.status(401).json({
                message: 'Password salah'
            });
        }

        const token = jwt.sign(
            {
                id: user.id,
                username: user.username,
                role: user.role
            },
            SECRET_KEY,
            { expiresIn: '24h' }
        );

        console.log('✨ Login berhasil:', username);

        res.json({
            message: 'Login berhasil',
            token,
            role: user.role
        });

    } catch (err) {
        console.error('❌ Login error:', err.message);
        res.status(500).json({
            message: err.message || 'Login gagal'
        });
    }

});


// =======================
// 📷 CHECK QR ELIGIBILITY & GENERATE OFFICE QR
// =======================
app.get("/check-qr-eligibility", verifyToken, async (req, res) => {
  try {
    // Get current date in Asia/Jakarta timezone
    const now = new Date();
    const jakartaDateString = now.toLocaleString("sv", { timeZone: "Asia/Jakarta" }).split(" ")[0]; // "YYYY-MM-DD"
    const jakartaDate = new Date(now.toLocaleString("en-US", { timeZone: "Asia/Jakarta" }));
    const dayOfWeek = jakartaDate.getDay(); // 0 = Sunday, 1 = Monday, ..., 6 = Saturday

    console.log(`Checking QR eligibility for date: ${jakartaDateString}, dayOfWeek: ${dayOfWeek}`);

    // Check if it's weekend (Saturday = 6, Sunday = 0)
    if (dayOfWeek === 0 || dayOfWeek === 6) {
      return res.json({
        eligible: false,
        reason: `Akhir pekan (${dayOfWeek === 0 ? "Minggu" : "Sabtu"})`,
        date: jakartaDateString
      });
    }

    // Check if it's before check-in starts
    const [workSettingsRows] = await db.query('SELECT * FROM settings_kerja LIMIT 1');
    if (workSettingsRows && workSettingsRows.length > 0) {
      const settings = workSettingsRows[0];
      const jamMasukAwal = settings.jam_masuk_awal ? String(settings.jam_masuk_awal) : '07:00:00';
      const normalizeT = (t) => t && t.length === 5 ? t + ':00' : (t || '07:00:00');
      const jamMasukAwalNorm = normalizeT(jamMasukAwal);

      const currentTimeStr = `${String(jakartaDate.getHours()).padStart(2,'0')}:${String(jakartaDate.getMinutes()).padStart(2,'0')}:00`;

      if (currentTimeStr < jamMasukAwalNorm) {
        return res.json({
          eligible: false,
          reason: `Belum masuk jam absen (Mulai pukul ${jamMasukAwalNorm.slice(0, 5)})`,
          date: jakartaDateString
        });
      }
    }

    // Fetch holidays from API
    let isHoliday = false;
    let holidayDescription = "";
    try {
      const year = jakartaDate.getFullYear();
      const holidayResponse = await axios.get(`https://api-hari-libur.vercel.app/api?year=${year}`, { timeout: 3000 });
      if (holidayResponse.data && holidayResponse.data.status === "success") {
        const holiday = holidayResponse.data.data.find(h => h.date === jakartaDateString);
        if (holiday) {
          isHoliday = true;
          holidayDescription = holiday.description;
        }
      }
    } catch (apiErr) {
      console.error("Gagal mengambil data libur nasional (menggunakan fallback):", apiErr.message);
    }

    if (isHoliday) {
      return res.json({
        eligible: false,
        reason: `Hari Libur Nasional (${holidayDescription})`,
        date: jakartaDateString
      });
    }

    return res.json({
      eligible: true,
      reason: "Hari Kerja (Senin - Jumat)",
      date: jakartaDateString
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.get("/generate-office-qr", verifyToken, async (req, res) => {
  try {
    const QRCode = require("qrcode");

    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: "Akses ditolak. Hanya admin yang dapat membuat QR Code." });
    }

    // Get current date in Asia/Jakarta timezone
    const now = new Date();
    const jakartaDateString = now.toLocaleString("sv", { timeZone: "Asia/Jakarta" }).split(" ")[0]; // "YYYY-MM-DD"
    const jakartaDate = new Date(now.toLocaleString("en-US", { timeZone: "Asia/Jakarta" }));
    const dayOfWeek = jakartaDate.getDay();

    if (dayOfWeek === 0 || dayOfWeek === 6) {
      return res.status(400).json({ message: "QR Code hanya dapat dibuat pada hari Senin - Jumat!" });
    }

    let isHoliday = false;
    let holidayDescription = "";
    try {
      const year = jakartaDate.getFullYear();
      const holidayResponse = await axios.get(`https://api-hari-libur.vercel.app/api?year=${year}`, { timeout: 3000 });
      if (holidayResponse.data && holidayResponse.data.status === "success") {
        const holiday = holidayResponse.data.data.find(h => h.date === jakartaDateString);
        if (holiday) {
          isHoliday = true;
          holidayDescription = holiday.description;
        }
      }
    } catch (apiErr) {
      console.error("Fallback holiday check:", apiErr.message);
    }

    if (isHoliday) {
      return res.status(400).json({ message: `QR Code tidak dapat dibuat pada hari libur nasional (${holidayDescription})!` });
    }

    const qrContent = `OFFICE-PRESENSI-QR-${jakartaDateString}`;
    const qrImage = await QRCode.toDataURL(qrContent, { width: 300, margin: 2 });

    res.json({
      qrContent,
      qrImage,
      date: jakartaDateString
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// =======================
// GET PEGAWAI
// =======================
app.get("/pegawai", verifyToken, checkDbReady, async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT 
        pegawai.id,
        pegawai.nama,
        pegawai.divisi_id,
        divisi.nama_divisi,
        pegawai.jabatan,
        pegawai.foto,
        users.username,
        users.password_raw
      FROM pegawai
      LEFT JOIN divisi ON pegawai.divisi_id = divisi.id
      LEFT JOIN users ON users.pegawai_id = pegawai.id
      WHERE (users.role != 'admin' OR users.role IS NULL)
    `);

    res.json({ data: rows });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// =======================
// ➕ TAMBAH PEGAWAI
// =======================
app.post("/pegawai", verifyToken, checkDbReady, async (req, res) => {
  try {
    // Check if user is admin
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: "Hanya admin yang dapat menambah pegawai baru." });
    }

    let { nama, divisi_id, jabatan, username, password } = req.body;
    if (nama) nama = nama.trim();
    if (username) username = username.trim();
    const valDivisiId = divisi_id === "" || divisi_id === undefined || divisi_id === null ? null : divisi_id;
    const valUsername = username || nama;

    if (!password) {
      return res.status(400).json({ message: "Password untuk akun baru wajib diisi!" });
    }

    const [result] = await db.query(
      "INSERT INTO pegawai (nama, divisi_id, jabatan) VALUES (?, ?, ?)",
      [nama, valDivisiId, jabatan]
    );

    const hash = await bcrypt.hash(password, 10);
    await db.query(
      "INSERT INTO users (username, password, password_raw, role, pegawai_id) VALUES (?, ?, ?, 'user', ?)",
      [valUsername, hash, password, result.insertId]
    );

    res.json({
      message: "Berhasil tambah pegawai dan akun login!",
      id: result.insertId,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// =======================
// ✏️ UPDATE PEGAWAI
// =======================
app.put("/pegawai/:id", verifyToken, checkDbReady, async (req, res) => {
  try {
    // Check if user is admin
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: "Hanya admin yang dapat mengubah data pegawai." });
    }

    const { nama, divisi_id, jabatan, foto } = req.body;
    const valDivisiId = divisi_id === "" || divisi_id === undefined || divisi_id === null ? null : divisi_id;

    if (foto) {
      // Update dengan foto
      await db.query(
        "UPDATE pegawai SET nama=?, divisi_id=?, jabatan=?, foto=? WHERE id=?",
        [nama, valDivisiId, jabatan, foto, req.params.id]
      );
    } else {
      // Update tanpa mengubah foto
      await db.query(
        "UPDATE pegawai SET nama=?, divisi_id=?, jabatan=? WHERE id=?",
        [nama, valDivisiId, jabatan, req.params.id]
      );
    }

    res.json({ message: "Berhasil update data pegawai" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// =======================
// ❌ DELETE PEGAWAI
// =======================
app.delete("/pegawai/:id", verifyToken, checkDbReady, async (req, res) => {
  try {
    // Check if user is admin
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: "Hanya admin yang dapat menghapus pegawai." });
    }

    // Cegah hapus pegawai yang terhubung ke akun admin
    const [linkedUser] = await db.query("SELECT role FROM users WHERE pegawai_id = ?", [req.params.id]);
    if (linkedUser.length > 0 && linkedUser[0].role === 'admin') {
      return res.status(403).json({ message: "Akun admin tidak dapat dihapus dari daftar pegawai!" });
    }

    // Hapus user terkait agar tidak bisa login lagi
    await db.query("DELETE FROM users WHERE pegawai_id = ? AND role != 'admin'", [req.params.id]);

    await db.query("DELETE FROM pegawai WHERE id=?", [req.params.id]);

    res.json({ message: "Berhasil menghapus pegawai beserta akun loginnya" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// =======================
// GET DIVISI
// =======================
app.get("/divisi", verifyToken, checkDbReady, async (req, res) => {
  try {
    const [rows] = await db.query("SELECT * FROM divisi");
    res.json({ data: rows });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// =======================
// ➕ TAMBAH DIVISI
// =======================
app.post("/divisi", verifyToken, checkDbReady, async (req, res) => {
  try {
    // Check if user is admin
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: "Hanya admin yang dapat menambah divisi baru." });
    }

    const { nama_divisi } = req.body;

    const [result] = await db.query(
      "INSERT INTO divisi (nama_divisi) VALUES (?)",
      [nama_divisi]
    );

    res.json({
      message: "Berhasil tambah divisi",
      id: result.insertId,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// =======================
// GET ABSENSI
// =======================
app.get("/absensi", verifyToken, checkDbReady, async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT
        absensi.id,
        absensi.pegawai_id,
        pegawai.nama,
        DATE_FORMAT(absensi.tanggal, '%Y-%m-%d') AS tanggal,
        absensi.status,
        absensi.alasan,
        absensi.foto_bukti,
        absensi.jam_masuk,
        absensi.jam_keluar,
        absensi.keterangan_jam
      FROM absensi
      JOIN pegawai ON absensi.pegawai_id = pegawai.id
    `);

    res.json({ data: rows });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// =======================
// ➕ TAMBAH ABSENSI (WITH CHECK-IN/CHECK-OUT & TERLAMBAT/LEMBUR DETECTION)
// =======================
app.post("/absensi", verifyToken, checkDbReady, async (req, res) => {
  try {
    const { pegawai_id, tanggal, tanggal_mulai, tanggal_selesai, jam_masuk, jam_keluar, status, alasan, foto_bukti } = req.body;

    const nowTime = new Date();
    const jakartaDate = new Date(nowTime.toLocaleString("en-US", { timeZone: "Asia/Jakarta" }));
    const defaultJamMasuk = jakartaDate.toTimeString().split(' ')[0].slice(0, 5); // "HH:MM"

    const startStr = tanggal_mulai || tanggal;
    const endStr = tanggal_selesai || tanggal;

    if (!startStr || !endStr) {
      return res.status(400).json({ message: "Tanggal tidak boleh kosong" });
    }

    const start = new Date(startStr + 'T00:00:00');
    const end = new Date(endStr + 'T00:00:00');
    const dateList = [];
    for (let d = new Date(start); d <= end; d.setDate(d.getDate() + 1)) {
      const y = d.getFullYear();
      const m = String(d.getMonth() + 1).padStart(2, '0');
      const day = String(d.getDate()).padStart(2, '0');
      dateList.push(`${y}-${m}-${day}`);
    }

    // ======= SPECIAL HANDLING FOR QR SCANNER (Hadir status, single day) =======
    if (status === "Hadir" && dateList.length === 1 && !tanggal_mulai) {
      // Get work settings for time calculations
      const [workSettings] = await db.query("SELECT * FROM settings_kerja LIMIT 1");
      const settings = workSettings[0] || {
        jam_masuk_awal: '07:00',
        jam_masuk_akhir: '09:00',
        jam_keluar_awal: '16:00',
        jam_keluar_akhir: '17:00'
      };

      console.log(`📋 Work Settings Loaded: jam_masuk_akhir=${settings.jam_masuk_akhir}, jam_keluar_akhir=${settings.jam_keluar_akhir}`);

      // Try to find existing record for today (any status)
      const [existingRecords] = await db.query(
        "SELECT * FROM absensi WHERE pegawai_id = ? AND tanggal = ?",
        [pegawai_id, dateList[0]]
      );

      const existingHadirRecord = existingRecords.find(r => r.status === 'Hadir');

      if (existingHadirRecord) {
        // ===== CHECK-OUT: Update existing record =====
        const scanTime = jam_masuk || defaultJamMasuk; // jam_masuk field contains the check-out time
        const normalizeTime = (t) => t && t.length === 5 ? t + ':00' : (t || '00:00:00');
        
        // If jam_keluar is already set, deny (already checked out)
        if (existingHadirRecord.jam_keluar) {
          return res.json({
            message: "Kamu sudah absen pulang!",
            id: null,
            dailyLimitExceeded: true
          });
        }

        // Check if the current time is before the allowed check-out time
        if (normalizeTime(scanTime) < normalizeTime(String(settings.jam_keluar_awal))) {
          return res.json({
            message: "Waktu absen pulang belum dimulai",
            id: null,
            dailyLimitExceeded: true
          });
        }

        // Check if the current time is after the allowed check-out time
        if (normalizeTime(scanTime) > normalizeTime(String(settings.jam_keluar_akhir))) {
          return res.json({
            message: "Waktu absen pulang sudah berakhir",
            id: null,
            dailyLimitExceeded: true
          });
        }

        // Preserve existing keterangan_jam from check-in (Terlambat stays), Lembur tracked separately
        let keteranganJam = existingHadirRecord.keterangan_jam || null;
        const isLembur = normalizeTime(scanTime) > normalizeTime(String(settings.jam_keluar_akhir)) ? 1 : 0;

        console.log(`🔍 CHECK-OUT Debug: scanTime=${scanTime}, jam_keluar_akhir=${settings.jam_keluar_akhir}, isLembur=${isLembur}, existingKeterangan=${existingHadirRecord.keterangan_jam}`);

        await db.query(
          "UPDATE absensi SET jam_keluar = ?, keterangan_jam = ?, is_lembur = ? WHERE id = ?",
          [scanTime, keteranganJam, isLembur, existingHadirRecord.id]
        );

        console.log(`✅ UPDATE successful: id=${existingHadirRecord.id}, keterangan_jam=${keteranganJam}, is_lembur=${isLembur}`);

        return res.json({
          message: "Check-out berhasil! " + (isLembur ? "Anda tercatat lembur hari ini." : ""),
          id: existingHadirRecord.id,
          limitExceeded: false,
          isLembur: isLembur === 1
        });
      } else if (existingRecords.length > 0) {
        // There is an existing record but it is NOT status 'Hadir' (e.g. Izin, Sakit, Pending, Alpa, Cuti)
        const record = existingRecords[0];
        let statusLabel = record.status;
        if (statusLabel === 'Pending Izin' || statusLabel === 'Pending Sakit') {
          statusLabel = `Pengajuan ${statusLabel.replace('Pending ', '')} (Pending)`;
        }
        return res.status(400).json({
          message: `Tidak dapat melakukan check-in karena Anda sedang dalam status: ${statusLabel}.`,
          limitExceeded: true
        });
      } else {
        // ===== CHECK-IN: Insert new record =====
        const checkInTime = jam_masuk || defaultJamMasuk;
        let keteranganJam = null;

        console.log(`🔍 CHECK-IN Debug: pegawai_id=${pegawai_id}, jam_masuk=${jam_masuk}, checkInTime=${checkInTime}, jam_masuk_akhir=${settings.jam_masuk_akhir}`);

        const normalizeTime = (t) => t && t.length === 5 ? t + ':00' : (t || '00:00:00');
        
        // Prevent checking in before jam_masuk_awal
        if (normalizeTime(checkInTime) < normalizeTime(String(settings.jam_masuk_awal))) {
          return res.json({
            message: "Jam absen belum dimulai",
            id: null,
            dailyLimitExceeded: true
          });
        }

        if (normalizeTime(checkInTime) > normalizeTime(String(settings.jam_masuk_akhir))) {
          return res.json({
            message: "Batas waktu absen masuk telah berakhir",
            id: null,
            dailyLimitExceeded: true
          });
        }

        const [result] = await db.query(
          `INSERT INTO absensi 
          (pegawai_id, tanggal, jam_masuk, jam_keluar, status, alasan, foto_bukti, keterangan_jam)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
          [pegawai_id, dateList[0], checkInTime, null, 'Hadir', alasan || null, foto_bukti || null, keteranganJam]
        );

        console.log(`✅ INSERT result: id=${result.insertId}, keterangan_jam=${keteranganJam}`);

        return res.json({
          message: "Check-in berhasil! " + (keteranganJam ? `Status: ${keteranganJam}` : ""),
          id: result.insertId,
          limitExceeded: false
        });
      }
    }

    // ======= NORMAL FLOW: Sakit, Izin, Pending, or manual entry =======
    // Validasi duplikasi: Cek apakah sudah ada catatan absensi untuk tanggal-tanggal yang diajukan
    const [existingAll] = await db.query(
      "SELECT DATE_FORMAT(tanggal, '%Y-%m-%d') as tanggal, status FROM absensi WHERE pegawai_id = ? AND tanggal IN (?)",
      [pegawai_id, dateList]
    );

    if (existingAll.length > 0) {
      const conflictDates = existingAll.map(row => {
        let statusLabel = row.status;
        if (statusLabel === 'Pending Izin' || statusLabel === 'Pending Sakit') {
          statusLabel = `Pengajuan ${statusLabel.replace('Pending ', '')} (Pending)`;
        }
        return `${row.tanggal} (${statusLabel})`;
      });
      return res.status(400).json({
        message: `Gagal mencatat absensi. Sudah ada riwayat absensi pada tanggal: ${conflictDates.join(', ')}.`,
        limitExceeded: false
      });
    }

    // Check if status is Sakit, Izin, or their Pending variants
    const isPendingOrLeave = ["Sakit", "Izin", "Pending Sakit", "Pending Izin"].includes(status);
    if (isPendingOrLeave) {
      // Validasi: tanggal mulai cuti wajib diisi
      if (!tanggal_mulai) {
        return res.status(400).json({
          message: "Tanggal mulai cuti wajib diisi untuk pengajuan Izin/Sakit.",
          limitExceeded: true
        });
      }

      // Tolak jika tanggal_mulai sudah lewat (tanggal lalu)
      const jakartaNowLeave = new Date(new Date().toLocaleString('en-US', { timeZone: 'Asia/Jakarta' }));
      const todayOnlyLeave = `${jakartaNowLeave.getFullYear()}-${String(jakartaNowLeave.getMonth()+1).padStart(2,'0')}-${String(jakartaNowLeave.getDate()).padStart(2,'0')}`;
      if (startStr < todayOnlyLeave) {
        return res.status(400).json({
          message: `Tidak dapat mengajukan Izin/Sakit untuk tanggal yang sudah lewat (${startStr}). Tanggal minimal adalah hari ini (${todayOnlyLeave}).`
        });
      }

      // 1. Hitung jumlah sakit/izin yang sudah diambil sebelumnya (termasuk Pending, hanya 7 hari kuota dasar)
      const [leaves] = await db.query(
        "SELECT COUNT(*) as count FROM absensi WHERE pegawai_id = ? AND (status IN ('Sakit', 'Izin', 'Pending Sakit', 'Pending Izin'))",
        [pegawai_id]
      );
      const leaveCount = leaves[0].count;

      // 2. Batas maksimal Izin/Sakit hanya 7 hari
      const maxAllowed = 7;

      if (leaveCount + dateList.length > maxAllowed) {
        // Untuk kebutuhan user: setelah melewati hari ke-7 harus pakai Cuti Tambahan.
        // Sesuai konfirmasi: untuk kasus ini kita tolak dengan pesan Cuti Tambahan.
        if (dateList.length === 1 && !tanggal_mulai) {
          // unreachable karena tanggal_mulai wajib, tapi jaga-jaga
          const [result] = await db.query(
            `INSERT INTO absensi 
            (pegawai_id, tanggal, jam_masuk, jam_keluar, status, alasan, foto_bukti)
            VALUES (?, ?, ?, ?, 'Alpa', ?, ?)`,
            [pegawai_id, dateList[0], jam_masuk || defaultJamMasuk, jam_keluar || null, alasan || null, foto_bukti || null]
          );

          return res.json({
            message: "Jatah Izin/Sakit Anda habis! Silakan ajukan Cuti Tambahan.",
            id: result.insertId,
            limitExceeded: true
          });
        }

        return res.status(400).json({
          message: "Jatah Izin/Sakit maksimal 7 hari. Jika lebih dari itu, silakan ajukan Cuti Tambahan.",
          limitExceeded: true
        });
      }
    }


    // Insert absensi normal / range
    let lastInsertId = null;
    for (const dt of dateList) {
      const [result] = await db.query(
        `INSERT INTO absensi 
        (pegawai_id, tanggal, jam_masuk, jam_keluar, status, alasan, foto_bukti, keterangan_jam)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [pegawai_id, dt, jam_masuk || defaultJamMasuk, jam_keluar || null, status, alasan || null, foto_bukti || null, null]
      );
      lastInsertId = result.insertId;
    }

    res.json({
      message: "Absensi berhasil dicatat",
      id: lastInsertId,
      limitExceeded: false
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.get("/test-route-new", (req, res) => {
  console.log("TEST ROUTE NEW HIT");
  res.json({message: "New test route works"});
});

// =======================
// GET CUTI TAMBAHAN
// =======================
console.log("DEBUG: Registering /cuti endpoint");
app.get("/cuti", verifyToken, checkDbReady, async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT cuti_tambahan.*, pegawai.nama, divisi.nama_divisi
      FROM cuti_tambahan
      JOIN pegawai ON cuti_tambahan.pegawai_id = pegawai.id
      LEFT JOIN divisi ON pegawai.divisi_id = divisi.id
      ORDER BY cuti_tambahan.id DESC
    `);
    res.json({ data: rows });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// =======================
// ✅ GROUP APPROVE ABSENSI (ACC semua pending dengan pegawai + alasan yang sama)
// PENTING: Harus dideklarasikan SEBELUM PUT /absensi/:id agar tidak konflik
// =======================
app.put("/absensi/group-approve", verifyToken, checkDbReady, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: "Hanya admin yang dapat mengubah status absensi." });
    }

    const { pegawai_id, alasan, old_status, new_status } = req.body;

    if (!pegawai_id || !old_status || !new_status) {
      return res.status(400).json({ message: "pegawai_id, old_status, new_status wajib diisi." });
    }

    if (!['Izin', 'Sakit', 'Ditolak'].includes(new_status)) {
      return res.status(400).json({ message: "new_status tidak valid." });
    }

    // Update semua record pending dengan pegawai_id & alasan & status lama yang sama
    const [result] = await db.query(
      "UPDATE absensi SET status = ? WHERE pegawai_id = ? AND status = ? AND (alasan = ? OR (alasan IS NULL AND ? IS NULL))",
      [new_status, pegawai_id, old_status, alasan, alasan]
    );

    res.json({
      message: `${result.affectedRows} record absensi berhasil diubah ke ${new_status}`,
      affected: result.affectedRows
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// =======================
// ✏️ UPDATE STATUS ABSENSI (APPROVE/REJECT IZIN/SAKIT - single)
// =======================
app.put("/absensi/:id", verifyToken, checkDbReady, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: "Hanya admin yang dapat mengubah status absensi." });
    }

    const { status } = req.body;
    const absensiId = req.params.id;

    const [existing] = await db.query("SELECT * FROM absensi WHERE id = ?", [absensiId]);
    if (existing.length === 0) {
      return res.status(404).json({ message: "Data absensi tidak ditemukan." });
    }

    await db.query("UPDATE absensi SET status = ? WHERE id = ?", [status, absensiId]);
    res.json({ message: `Status absensi berhasil diubah menjadi ${status}` });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Endpoint /ketidakhadiran sekarang menggunakan logic lengkap dari file routes/ketidakhadiran.js (Izin/Sakit + Cuti Tambahan Disetujui).
// Pastikan import router di bagian bawah (sudah disiapkan).

const ketidakhadiranRoute = require('./routes/ketidakhadiran');
ketidakhadiranRoute(app, () => db, verifyToken, checkDbReady);



// =======================
// ➕ AJUKAN CUTI TAMBAHAN
// =======================
app.post("/cuti", verifyToken, checkDbReady, async (req, res) => {
  try {
    const { pegawai_id, tanggal_mulai, tanggal_selesai, keperluan, alasan, foto_bukti } = req.body;
    
    if (!tanggal_mulai || !tanggal_selesai) {
      return res.status(400).json({ message: "Tanggal mulai dan selesai harus diisi" });
    }

    // Tolak jika tanggal_mulai sudah lewat (tanggal lalu)
    const jakartaToday = new Date(new Date().toLocaleString('en-US', { timeZone: 'Asia/Jakarta' }));
    const todayOnly = `${jakartaToday.getFullYear()}-${String(jakartaToday.getMonth()+1).padStart(2,'0')}-${String(jakartaToday.getDate()).padStart(2,'0')}`;
    if (tanggal_mulai < todayOnly) {
      return res.status(400).json({ message: `Tidak dapat mengajukan cuti untuk tanggal yang sudah lewat (${tanggal_mulai}). Tanggal minimal adalah hari ini (${todayOnly}).` });
    }

    const start = new Date(tanggal_mulai);
    const end = new Date(tanggal_selesai);
    const durasi_hari = Math.round((end - start) / (1000 * 60 * 60 * 24)) + 1;

    if (durasi_hari <= 0) {
      return res.status(400).json({ message: "Tanggal selesai harus setelah atau sama dengan tanggal mulai" });
    }

    if (keperluan === "Izin/Sakit Lanjutan" && durasi_hari > 5) {
      return res.status(400).json({ message: "Kategori Izin/Sakit Lanjutan maksimal 5 hari!" });
    }

    const tanggal_pengajuan = new Date().toISOString().split('T')[0];

    await db.query(
      `INSERT INTO cuti_tambahan 
      (pegawai_id, tanggal_pengajuan, tanggal_mulai, tanggal_selesai, keperluan, alasan, foto_bukti, durasi_hari, status) 
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Pending')`,
      [pegawai_id, tanggal_pengajuan, tanggal_mulai, tanggal_selesai, keperluan, alasan, foto_bukti, durasi_hari]
    );

    res.json({ message: "Pengajuan Cuti Tambahan berhasil diajukan! Menunggu ACC Admin." });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// =======================
// ✏️ APPROVE MULTIPLE CUTI (BATCH) - HARUS SEBELUM :id!
// =======================
app.put("/cuti/batch-approve", verifyToken, checkDbReady, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: "Hanya admin yang dapat approve cuti." });
    }

    const { ids } = req.body; // array of cuti IDs
    if (!Array.isArray(ids) || ids.length === 0) {
      return res.status(400).json({ message: "IDs harus berupa array tidak kosong." });
    }

    let successCount = 0;
    let errorList = [];

    for (const cutiId of ids) {
      try {
        // Ambil data cuti
        const [cutiRows] = await db.query("SELECT * FROM cuti_tambahan WHERE id = ?", [cutiId]);
        if (cutiRows.length === 0) {
          errorList.push(`Cuti ID ${cutiId} tidak ditemukan`);
          continue;
        }
        const cuti = cutiRows[0];

        // Update status cuti ke Disetujui
        await db.query("UPDATE cuti_tambahan SET status = 'Disetujui' WHERE id = ?", [cutiId]);

        // Reset notifikasi
        await db.query(
          "UPDATE cuti_tambahan SET notified_status = NULL, notified_at = NULL WHERE id = ?",
          [cutiId]
        );

        // Auto-insert absensi harian untuk setiap hari kerja dalam periode cuti
        if (cuti.tanggal_mulai && cuti.tanggal_selesai) {
          const start = new Date(cuti.tanggal_mulai);
          const end = new Date(cuti.tanggal_selesai);

          for (let d = new Date(start); d <= end; d.setDate(d.getDate() + 1)) {
            const dow = d.getDay(); // 0=Minggu, 6=Sabtu
            if (dow === 0 || dow === 6) continue; // skip weekend

            const y = d.getFullYear();
            const m = String(d.getMonth() + 1).padStart(2, '0');
            const day = String(d.getDate()).padStart(2, '0');
            const tanggal = `${y}-${m}-${day}`;

            // Cek apakah sudah ada record untuk hari itu
            const [existing] = await db.query(
              "SELECT id FROM absensi WHERE pegawai_id = ? AND tanggal = ?",
              [cuti.pegawai_id, tanggal]
            );

            if (existing.length === 0) {
              await db.query(
                `INSERT INTO absensi (pegawai_id, tanggal, jam_masuk, jam_keluar, status, alasan)
                 VALUES (?, ?, '00:00', '00:00', 'Cuti', ?)`,
                [cuti.pegawai_id, tanggal, `Cuti Tambahan - ${cuti.keperluan || 'Disetujui'}`]
              );
            } else {
              // Jika ada record dan statusnya Alpa / Pending, update ke Cuti
              await db.query(
                "UPDATE absensi SET status = 'Cuti', alasan = ? WHERE pegawai_id = ? AND tanggal = ? AND status IN ('Alpa', 'Pending', 'Pending Izin', 'Pending Sakit')",
                [`Cuti Tambahan - ${cuti.keperluan || 'Disetujui'}`, cuti.pegawai_id, tanggal]
              );
            }
          }
        }

        successCount++;
      } catch (err) {
        console.error(`Error approving cuti ID ${cutiId}:`, err);
        errorList.push(`Cuti ID ${cutiId}: ${err.message}`);
      }
    }

    const message = errorList.length === 0 
      ? `${successCount} pengajuan cuti berhasil disetujui.`
      : `${successCount} berhasil, ${errorList.length} gagal: ${errorList.join('; ')}`;

    res.json({ message, successCount, errorCount: errorList.length });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// =======================
// ✏️ UPDATE STATUS CUTI (ACC ADMIN) - auto-insert absensi harian saat disetujui
// =======================
app.put("/cuti/:id", verifyToken, checkDbReady, async (req, res) => {
  try {
    const { status } = req.body; // 'Disetujui' atau 'Ditolak'

    if (!['Disetujui', 'Ditolak'].includes(status)) {
      return res.status(400).json({ message: "Status cuti tidak valid" });
    }

    const cutiId = req.params.id;

    // Ambil data cuti
    const [cutiRows] = await db.query("SELECT * FROM cuti_tambahan WHERE id = ?", [cutiId]);
    if (cutiRows.length === 0) {
      return res.status(404).json({ message: "Data cuti tidak ditemukan." });
    }
    const cuti = cutiRows[0];

    // Update status cuti
    await db.query("UPDATE cuti_tambahan SET status = ? WHERE id = ?", [status, cutiId]);

    // Reset notifikasi
    await db.query(
      "UPDATE cuti_tambahan SET notified_status = NULL, notified_at = NULL WHERE id = ?",
      [cutiId]
    );

    // Jika disetujui: auto-insert absensi harian untuk setiap hari kerja dalam periode cuti
    if (status === 'Disetujui' && cuti.tanggal_mulai && cuti.tanggal_selesai) {
      const start = new Date(cuti.tanggal_mulai);
      const end = new Date(cuti.tanggal_selesai);

      for (let d = new Date(start); d <= end; d.setDate(d.getDate() + 1)) {
        const dow = d.getDay(); // 0=Minggu, 6=Sabtu
        if (dow === 0 || dow === 6) continue; // skip weekend

        const y = d.getFullYear();
        const m = String(d.getMonth() + 1).padStart(2, '0');
        const day = String(d.getDate()).padStart(2, '0');
        const tanggal = `${y}-${m}-${day}`;

        // Cek apakah sudah ada record untuk hari itu
        const [existing] = await db.query(
          "SELECT id FROM absensi WHERE pegawai_id = ? AND tanggal = ?",
          [cuti.pegawai_id, tanggal]
        );

        if (existing.length === 0) {
          await db.query(
            `INSERT INTO absensi (pegawai_id, tanggal, jam_masuk, jam_keluar, status, alasan)
             VALUES (?, ?, '00:00', '00:00', 'Cuti', ?)`,
            [cuti.pegawai_id, tanggal, `Cuti Tambahan - ${cuti.keperluan || 'Disetujui'}`]
          );
        } else {
          // Jika ada record dan statusnya Alpa / Pending, update ke Cuti
          await db.query(
            "UPDATE absensi SET status = 'Cuti', alasan = ? WHERE pegawai_id = ? AND tanggal = ? AND status IN ('Alpa', 'Pending', 'Pending Izin', 'Pending Sakit')",
            [`Cuti Tambahan - ${cuti.keperluan || 'Disetujui'}`, cuti.pegawai_id, tanggal]
          );
        }
      }
    }

    res.json({ message: `Pengajuan cuti telah ${status}` });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// =======================
// 🔔 NOTIF CUTI UNTUK USER (Disetujui/Ditolak)
// =======================
app.get("/cuti/notif", verifyToken, checkDbReady, async (req, res) => {
  try {
    if (req.user.role !== 'user') {
      return res.status(403).json({ message: "Hanya user yang dapat melihat notifikasi cuti." });
    }

    // Ambil pegawai_id dari user
    const [userRows] = await db.query("SELECT pegawai_id FROM users WHERE id = ?", [req.user.id]);
    const pegawaiId = userRows?.[0]?.pegawai_id;
    if (!pegawaiId) {
      return res.json({ data: [] });
    }

    const [rows] = await db.query(
      `SELECT
        c.id,
        c.status,
        c.keperluan,
        c.alasan,
        c.foto_bukti,
        c.durasi_hari,
        c.tanggal_mulai,
        c.tanggal_selesai,
        c.notified_status
      FROM cuti_tambahan c
      WHERE c.pegawai_id = ?
        AND c.status IN ('Disetujui','Ditolak')
        AND (c.notified_status IS NULL OR c.notified_status <> c.status)
      ORDER BY c.id DESC
    `,
      [pegawaiId]
    );

    res.json({ data: rows });
  } catch (err) {
    console.error('Error /cuti/notif:', err);
    res.status(500).json({ message: err.message });
  }
});

// Tandai notifikasi cuti sebagai dibaca
app.post("/cuti/notif/read", verifyToken, checkDbReady, async (req, res) => {
  try {
    if (req.user.role !== 'user') {
      return res.status(403).json({ message: "Hanya user yang dapat menandai notifikasi." });
    }

    const { cuti_ids } = req.body;
    if (!Array.isArray(cuti_ids) || cuti_ids.length === 0) {
      return res.status(400).json({ message: "cuti_ids wajib diisi" });
    }

    const [userRows] = await db.query("SELECT pegawai_id FROM users WHERE id = ?", [req.user.id]);
    const pegawaiId = userRows?.[0]?.pegawai_id;
    if (!pegawaiId) {
      return res.status(404).json({ message: "User tidak memiliki pegawai_id" });
    }

    // Ambil status aktual per cuti agar notified_status diset sesuai status saat ini
    const placeholders = cuti_ids.map(() => '?').join(',');
    const [cutiRows] = await db.query(
      `SELECT id, status FROM cuti_tambahan WHERE pegawai_id = ? AND id IN (${placeholders})`,
      [pegawaiId, ...cuti_ids]
    );

    if (cutiRows.length === 0) {
      return res.json({ message: 'Tidak ada data yang bisa ditandai.' });
    }

    const now = new Date();
    const promises = cutiRows.map(c => {
      return db.query(
        "UPDATE cuti_tambahan SET notified_status = ?, notified_at = ? WHERE id = ?",
        [c.status, now, c.id]
      );
    });

    await Promise.all(promises);
    res.json({ message: 'Notifikasi ditandai dibaca.' });
  } catch (err) {
    console.error('Error /cuti/notif/read:', err);
    res.status(500).json({ message: err.message });
  }
});

// =======================
// ⏰ JOB HARIAN: Cuti Ditolak => Jika tanggal lewat dan pegawai belum absen => Alpa
// =======================
let lastAlpaJobDate = null;
setInterval(async () => {
  try {
    if (!db) return;

    // 1x per hari (Asia/Jakarta) - jalan jam setelah proses mulai (cek idempotent dengan lastAlpaJobDate)
    const now = new Date();
    const jakartaNow = new Date(now.toLocaleString('en-US', { timeZone: 'Asia/Jakarta' }));
    const todayStr = jakartaNow.toISOString().split('T')[0];

    if (lastAlpaJobDate === todayStr) return;

    // Pastikan hanya sekali setelah start; set sekarang
    lastAlpaJobDate = todayStr;

    // Ambil semua cuti ditolak yang rentangnya mencakup today
    const [cutiRows] = await db.query(
      `SELECT id, pegawai_id, keperluan, alasan, foto_bukti, tanggal_mulai, tanggal_selesai
       FROM cuti_tambahan
       WHERE status = 'Ditolak'
         AND tanggal_mulai <= ?
         AND tanggal_selesai >= ?`,
      [todayStr, todayStr]
    );

    if (!cutiRows || cutiRows.length === 0) {
      return;
    }

    for (const c of cutiRows) {
      const [already] = await db.query(
        "SELECT id FROM absensi WHERE pegawai_id = ? AND tanggal = ? LIMIT 1",
        [c.pegawai_id, todayStr]
      );
      if (already.length > 0) continue;

      const reasonText = `Cuti Ditolak: ${c.keperluan || 'Cuti Tambahan'} - ${c.alasan || ''}`.trim();

      await db.query(
        `INSERT INTO absensi
          (pegawai_id, tanggal, jam_masuk, jam_keluar, status, alasan, foto_bukti, keterangan_jam)
         VALUES (?, ?, ?, ?, 'Alpa', ?, ?, NULL)`,
        [c.pegawai_id, todayStr, '00:00', null, reasonText || null, c.foto_bukti || null]
      );
    }
  } catch (err) {
    console.error('Alpa job error:', err);
  }
}, 60 * 1000);

// =======================
// ⏰ JOB HARIAN: Auto-Alpa setelah batas jam masuk berakhir (hanya hari kerja)
// Setiap menit dicek, jika jam sekarang >= jam_masuk_akhir dan belum dijalankan hari ini => insert Alpa
// =======================
let lastAutoAlpaDate = null;
setInterval(async () => {
  try {
    if (!db) return;

    const now = new Date();
    const jakartaNow = new Date(now.toLocaleString('en-US', { timeZone: 'Asia/Jakarta' }));
    const todayStr = `${jakartaNow.getFullYear()}-${String(jakartaNow.getMonth()+1).padStart(2,'0')}-${String(jakartaNow.getDate()).padStart(2,'0')}`;
    const currentTimeStr = `${String(jakartaNow.getHours()).padStart(2,'0')}:${String(jakartaNow.getMinutes()).padStart(2,'0')}:00`;

    // Jangan jalankan jika sudah dijalankan hari ini
    if (lastAutoAlpaDate === todayStr) return;

    // Skip weekend (Sabtu=6, Minggu=0)
    const dayOfWeek = jakartaNow.getDay();
    if (dayOfWeek === 0 || dayOfWeek === 6) {
      lastAutoAlpaDate = todayStr; // skip hari ini
      return;
    }

    // Ambil settings jam kerja
    const [workSettingsRows] = await db.query('SELECT * FROM settings_kerja LIMIT 1');
    if (!workSettingsRows || workSettingsRows.length === 0) return;
    const settings = workSettingsRows[0];

    // Normalize jam_masuk_akhir
    const jamMasukAkhir = String(settings.jam_masuk_akhir);
    const normalizeT = (t) => t && t.length === 5 ? t + ':00' : (t || '00:00:00');
    const jamMasukAkhirNorm = normalizeT(jamMasukAkhir);

    // Jalankan hanya setelah jam_masuk_akhir
    if (currentTimeStr < jamMasukAkhirNorm) return;

    // Cek hari libur nasional via API
    try {
      const year = jakartaNow.getFullYear();
      const holidayResponse = await axios.get(`https://api-hari-libur.vercel.app/api?year=${year}`, { timeout: 3000 });
      if (holidayResponse.data && holidayResponse.data.status === 'success') {
        const holiday = holidayResponse.data.data.find(h => h.date === todayStr);
        if (holiday) {
          console.log(`[AutoAlpa] Hari ini adalah hari libur nasional: ${holiday.description} - skip`);
          lastAutoAlpaDate = todayStr;
          return;
        }
      }
    } catch (apiErr) {
      console.warn('[AutoAlpa] Gagal cek hari libur nasional, lanjutkan:', apiErr.message);
    }

    // Tandai sudah dijalankan hari ini
    lastAutoAlpaDate = todayStr;

    console.log(`[AutoAlpa] Menjalankan auto-alpa untuk tanggal ${todayStr} (jam masuk berakhir ${jamMasukAkhirNorm})`);

    // Ambil semua pegawai aktif
    const [allPegawai] = await db.query('SELECT id FROM pegawai');
    if (!allPegawai || allPegawai.length === 0) return;

    // Ambil yang sudah absen hari ini (status apapun)
    const [hadirRows] = await db.query(
      'SELECT DISTINCT pegawai_id FROM absensi WHERE tanggal = ?',
      [todayStr]
    );
    const hadirIds = new Set(hadirRows.map(r => r.pegawai_id));

    // Ambil yang punya cuti tambahan disetujui hari ini
    const [cutiApprovedRows] = await db.query(
      `SELECT DISTINCT pegawai_id FROM cuti_tambahan
       WHERE LOWER(status) = 'disetujui'
       AND tanggal_mulai <= ? AND tanggal_selesai >= ?`,
      [todayStr, todayStr]
    );
    const cutiIds = new Set(cutiApprovedRows.map(r => r.pegawai_id));

    let insertCount = 0;
    for (const pegawai of allPegawai) {
      // Skip yang sudah ada catatan absensi
      if (hadirIds.has(pegawai.id)) continue;
      // Skip yang sedang cuti tambahan disetujui
      if (cutiIds.has(pegawai.id)) continue;

      // Insert Alpa
      await db.query(
        `INSERT INTO absensi
          (pegawai_id, tanggal, jam_masuk, jam_keluar, status, alasan, foto_bukti, keterangan_jam)
         VALUES (?, ?, NULL, NULL, 'Alpa', 'Tidak melakukan absensi masuk', NULL, NULL)`,
        [pegawai.id, todayStr]
      );
      insertCount++;
    }

    console.log(`[AutoAlpa] Selesai: ${insertCount} pegawai ditandai Alpa untuk tanggal ${todayStr}`);
  } catch (err) {
    console.error('[AutoAlpa] Error:', err);
  }
}, 60 * 1000);

// =======================
// ⏰ JOB HARIAN: Auto-Lembur - Jika belum checkout sebelum akhir hari (23:59)
// Job berjalan setiap menit, trigger saat sudah lewat jam 23:55
// Karyawan yang belum pulang akan auto-checkout di 23:59 dengan mark lembur
// =======================
let lastAutoLemburDate = null;
setInterval(async () => {
  try {
    if (!db) return;

    const now = new Date();
    const jakartaNow = new Date(now.toLocaleString('en-US', { timeZone: 'Asia/Jakarta' }));
    const todayStr = `${jakartaNow.getFullYear()}-${String(jakartaNow.getMonth()+1).padStart(2,'0')}-${String(jakartaNow.getDate()).padStart(2,'0')}`;
    const currentTimeStr = `${String(jakartaNow.getHours()).padStart(2,'0')}:${String(jakartaNow.getMinutes()).padStart(2,'0')}:00`;

    // Jangan jalankan jika sudah dijalankan hari ini
    if (lastAutoLemburDate === todayStr) return;

    // Skip weekend (Sabtu=6, Minggu=0)
    const dayOfWeek = jakartaNow.getDay();
    if (dayOfWeek === 0 || dayOfWeek === 6) {
      lastAutoLemburDate = todayStr; // skip hari ini
      return;
    }

    // Jalankan hanya setelah jam 23:55 (untuk catch end-of-day)
    if (currentTimeStr < '23:55:00') return;

    // Tandai sudah dijalankan hari ini
    lastAutoLemburDate = todayStr;

    console.log(`[AutoLembur] Menjalankan auto-lembur untuk tanggal ${todayStr} (end-of-day 23:59)`);

    // Cek hari libur nasional via API
    try {
      const year = jakartaNow.getFullYear();
      const holidayResponse = await axios.get(`https://api-hari-libur.vercel.app/api?year=${year}`, { timeout: 3000 });
      if (holidayResponse.data && holidayResponse.data.status === 'success') {
        const holiday = holidayResponse.data.data.find(h => h.date === todayStr);
        if (holiday) {
          console.log(`[AutoLembur] Hari ini adalah hari libur nasional: ${holiday.description} - skip`);
          return;
        }
      }
    } catch (apiErr) {
      console.warn('[AutoLembur] Gagal cek hari libur nasional, lanjutkan:', apiErr.message);
    }

    // Ambil semua karyawan yang sudah check-in tapi belum check-out hari ini
    const [notCheckedOutRows] = await db.query(
      `SELECT a.id, a.pegawai_id, a.jam_masuk FROM absensi a
       WHERE a.tanggal = ?
         AND a.jam_masuk IS NOT NULL
         AND a.jam_keluar IS NULL
         AND a.status = 'Hadir'`,
      [todayStr]
    );

    if (!notCheckedOutRows || notCheckedOutRows.length === 0) {
      console.log(`[AutoLembur] Tidak ada karyawan yang belum checkout untuk tanggal ${todayStr}`);
      return;
    }

    // Ambil karyawan yang sedang cuti tambahan disetujui hari ini
    const [cutiApprovedRows] = await db.query(
      `SELECT DISTINCT pegawai_id FROM cuti_tambahan
       WHERE LOWER(status) = 'disetujui'
       AND tanggal_mulai <= ? AND tanggal_selesai >= ?`,
      [todayStr, todayStr]
    );
    const cutiIds = new Set(cutiApprovedRows.map(r => r.pegawai_id));

    let updateCount = 0;
    for (const record of notCheckedOutRows) {
      // Skip yang sedang cuti tambahan disetujui
      if (cutiIds.has(record.pegawai_id)) continue;

      // Update checkout dengan 23:59 dan tandai lembur (karena melewati jam 17:00)
      const [result] = await db.query(
        `UPDATE absensi 
         SET jam_keluar = '23:59', 
             is_lembur = 1,
             keterangan_jam = 'Lembur'
         WHERE id = ? AND jam_keluar IS NULL`,
        [record.id]
      );

      if (result.affectedRows > 0) {
        updateCount++;
        console.log(`[AutoLembur] Auto checkout untuk pegawai_id ${record.pegawai_id} - jam 23:59, marked as Lembur`);
      }
    }

    console.log(`[AutoLembur] Selesai: ${updateCount} karyawan auto-checkout sebagai Lembur untuk tanggal ${todayStr}`);
  } catch (err) {
    console.error('[AutoLembur] Error:', err);
  }
}, 60 * 1000);

// =======================
// 🔐 GANTI PASSWORD
// =======================
app.post("/change-password", verifyToken, async (req, res) => {
  try {
    const { old_password, new_password } = req.body;
    const userId = req.user.id;

    if (!new_password) {
      return res.status(400).json({ message: "Password baru wajib diisi!" });
    }

    const [rows] = await db.query("SELECT * FROM users WHERE id = ?", [userId]);
    if (rows.length === 0) {
      return res.status(404).json({ message: "User tidak ditemukan" });
    }

    const user = rows[0];
    if (old_password) {
      const valid = await bcrypt.compare(old_password, user.password);
      if (!valid) {
        return res.status(400).json({ message: "Password lama salah!" });
      }
    }

    const hash = await bcrypt.hash(new_password, 10);
    await db.query("UPDATE users SET password = ? WHERE id = ?", [hash, userId]);

    res.json({ message: "Password berhasil diperbarui!" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ================================
// UPDATE USER PROFILE (USER ONLY)
// ================================
app.put("/user/profile", verifyToken, checkDbReady, async (req, res) => {
  try {
    const userId = req.user.id;
    const { foto, no_telepon, alamat, tanggal_lahir, jenis_kelamin } = req.body;

    // Get pegawai_id from users table
    const [userRows] = await db.query("SELECT pegawai_id FROM users WHERE id = ?", [userId]);
    if (userRows.length === 0) {
      return res.status(404).json({ message: "User tidak ditemukan" });
    }

    const pegawaiId = userRows[0].pegawai_id;

    if (pegawaiId) {
      // Build update query dynamically based on provided fields
      let updateFields = [];
      let updateValues = [];

      if (foto) {
        updateFields.push("foto = ?");
        updateValues.push(foto);
      }
      if (no_telepon !== undefined) {
        updateFields.push("no_telepon = ?");
        updateValues.push(no_telepon);
      }
      if (alamat !== undefined) {
        updateFields.push("alamat = ?");
        updateValues.push(alamat);
      }
      if (tanggal_lahir !== undefined) {
        updateFields.push("tanggal_lahir = ?");
        updateValues.push(tanggal_lahir);
      }
      if (jenis_kelamin !== undefined) {
        updateFields.push("jenis_kelamin = ?");
        updateValues.push(jenis_kelamin);
      }

      if (updateFields.length > 0) {
        updateValues.push(pegawaiId);
        const query = `UPDATE pegawai SET ${updateFields.join(", ")} WHERE id = ?`;
        await db.query(query, updateValues);
      }
    }

    res.json({ message: "Profil berhasil diperbarui!" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// =======================
// 🚀 RUN SERVER
// =======================
// Tunggu database initialize selesai, baru start server
// =======================
// 🎫 QR CODE MANAGEMENT ENDPOINTS
// =======================

// ➕ GENERATE QR CODE UNTUK USER (ADMIN ONLY)
app.post("/qr-code/generate", verifyToken, checkDbReady, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: "Hanya admin yang dapat membuat QR Code." });
    }

    const { pegawai_id, tanggal_berlaku } = req.body;

    if (!pegawai_id || !tanggal_berlaku) {
      return res.status(400).json({ message: "pegawai_id dan tanggal_berlaku wajib diisi!" });
    }

    // Validasi pegawai ada
    const [pegawai] = await db.query("SELECT * FROM pegawai WHERE id = ?", [pegawai_id]);
    if (pegawai.length === 0) {
      return res.status(404).json({ message: "Pegawai tidak ditemukan." });
    }

    // Generate unique QR code
    const randomCode = Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
    const qrCode = `PRESENSI-${pegawai_id}-${randomCode.toUpperCase()}`;

    // Set expired time to 23:59:59 on the specified date
    const expiredDate = new Date(tanggal_berlaku);
    expiredDate.setHours(23, 59, 59, 999);

    const [result] = await db.query(
      "INSERT INTO qr_codes (pegawai_id, qr_code, tanggal_berlaku, tanggal_kadaluarsa, status) VALUES (?, ?, ?, ?, 'active')",
      [pegawai_id, qrCode, tanggal_berlaku, expiredDate]
    );

    res.json({
      message: "QR Code berhasil dibuat",
      id: result.insertId,
      qr_code: qrCode,
      pegawai_nama: pegawai[0].nama,
      tanggal_berlaku,
      status: "active"
    });
  } catch (err) {
    console.error("Error generating QR code:", err);
    res.status(500).json({ message: err.message });
  }
});

// GET QR CODES - ADMIN SEES ALL, USER SEES THEIR OWN
app.get("/qr-code/list", verifyToken, checkDbReady, async (req, res) => {
  try {
    let query = `
      SELECT 
        qr.id,
        qr.qr_code,
        qr.tanggal_dibuat,
        qr.tanggal_berlaku,
        qr.tanggal_kadaluarsa,
        qr.status,
        qr.digunakan_pada,
        p.id as pegawai_id,
        p.nama as pegawai_nama
      FROM qr_codes qr
      JOIN pegawai p ON qr.pegawai_id = p.id
    `;

    let params = [];

    // Jika user (bukan admin), hanya tampilkan QR mereka sendiri
    if (req.user.role !== 'admin') {
      const [user] = await db.query("SELECT pegawai_id FROM users WHERE id = ?", [req.user.id]);
      if (user.length > 0 && user[0].pegawai_id) {
        query += " WHERE qr.pegawai_id = ?";
        params.push(user[0].pegawai_id);
      }
    }

    query += " ORDER BY qr.tanggal_dibuat DESC";

    const [rows] = await db.query(query, params);
    res.json({ data: rows });
  } catch (err) {
    console.error("Error fetching QR codes:", err);
    res.status(500).json({ message: err.message });
  }
});

// ✅ SCAN QR CODE - MARK ATTENDANCE
app.post("/qr-code/scan", verifyToken, checkDbReady, async (req, res) => {
  try {
    const { qr_code } = req.body;

    if (!qr_code) {
      return res.status(400).json({ message: "QR Code wajib diisi!" });
    }

    // Get QR code details
    const [qrRows] = await db.query(
      "SELECT * FROM qr_codes WHERE qr_code = ?",
      [qr_code]
    );

    if (qrRows.length === 0) {
      return res.status(404).json({ message: "QR Code tidak ditemukan atau tidak valid!" });
    }

    const qrData = qrRows[0];

    // Check if already used
    if (qrData.status === 'used') {
      return res.status(400).json({ message: "QR Code ini sudah pernah digunakan!" });
    }

    // Check if expired
    const now = new Date();
    if (qrData.tanggal_kadaluarsa && new Date(qrData.tanggal_kadaluarsa) < now) {
      await db.query("UPDATE qr_codes SET status = 'expired' WHERE id = ?", [qrData.id]);
      return res.status(400).json({ message: "QR Code sudah kadaluarsa!" });
    }

    // Check if user owns this QR code (skip for admin)
    if (req.user.role !== 'admin') {
      const [user] = await db.query("SELECT pegawai_id FROM users WHERE id = ?", [req.user.id]);
      if (!user || !user[0] || user[0].pegawai_id !== qrData.pegawai_id) {
        return res.status(403).json({ message: "QR Code ini bukan milik Anda!" });
      }
    }

    // Get current date in Jakarta timezone
    const jakartaDate = new Date(now.toLocaleString("en-US", { timeZone: "Asia/Jakarta" }));
    const todayStr = jakartaDate.toISOString().split('T')[0];

    // Check if check-in hours have started
    const [workSettings] = await db.query("SELECT * FROM settings_kerja LIMIT 1");
    const settings = workSettings[0] || {
      jam_masuk_awal: '07:00',
      jam_masuk_akhir: '09:00',
      jam_keluar_awal: '16:00',
      jam_keluar_akhir: '17:00'
    };
    const jamMasukScan = jakartaDate.toTimeString().split(' ')[0];
    const normalizeTime = (t) => t && t.length === 5 ? t + ':00' : (t || '00:00:00');

    if (normalizeTime(jamMasukScan) < normalizeTime(String(settings.jam_masuk_awal))) {
      return res.status(400).json({ message: "Jam absen belum dimulai" });
    }

    // Check if already absent today
    const [existingAbsensi] = await db.query(
      "SELECT * FROM absensi WHERE pegawai_id = ? AND tanggal = ?",
      [qrData.pegawai_id, todayStr]
    );

    if (existingAbsensi.length > 0) {
      const record = existingAbsensi[0];
      if (record.status === 'Hadir') {
        if (record.jam_keluar) {
          return res.status(400).json({ message: "Kamu sudah absen pulang!" });
        } else {
          return res.status(400).json({ message: "Kamu sudah absen masuk!" });
        }
      } else if (['Izin', 'Sakit', 'Pending Izin', 'Pending Sakit'].includes(record.status)) {
        return res.status(400).json({
          message: `Tidak dapat melakukan absensi masuk karena Anda sedang dalam status: ${record.status}.`
        });
      } else if (record.status === 'Cuti') {
        return res.status(400).json({
          message: "Tidak dapat melakukan absensi masuk karena Anda sedang Cuti."
        });
      } else if (record.status === 'Alpa') {
        return res.status(400).json({
          message: "Tidak dapat melakukan absensi masuk karena Anda sudah ditandai Alpa hari ini."
        });
      } else {
        return res.status(400).json({
          message: `Kamu sudah memiliki catatan absensi dengan status: ${record.status}`
        });
      }
    }

    // Insert attendance record
    const jamMasuk = jakartaDate.toTimeString().split(' ')[0];
    let keteranganJam = null;
    if (normalizeTime(jamMasuk) > normalizeTime(String(settings.jam_masuk_akhir))) {
      keteranganJam = 'Terlambat';
    }

    const [absensiResult] = await db.query(
      "INSERT INTO absensi (pegawai_id, tanggal, jam_masuk, status, keterangan_jam) VALUES (?, ?, ?, 'Hadir', ?)",
      [qrData.pegawai_id, todayStr, jamMasuk, keteranganJam]
    );

    // Update QR code to used
    const now2 = new Date();
    await db.query(
      "UPDATE qr_codes SET status = 'used', digunakan_pada = ? WHERE id = ?",
      [now2, qrData.id]
    );

    res.json({
      message: "Absensi berhasil dicatat! ✅",
      absensi_id: absensiResult.insertId,
      tanggal: todayStr,
      jam_masuk: jamMasuk,
      status: "Hadir"
    });
  } catch (err) {
    console.error("Error scanning QR code:", err);
    res.status(500).json({ message: err.message });
  }
});

// ==========================================
// 📤 CHECKOUT (SCAN PULANG) - ADMIN ONLY
// ==========================================
app.post("/checkout", verifyToken, checkDbReady, async (req, res) => {
  try {
    // Admin only
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: "Hanya admin yang dapat melakukan scan checkout!" });
    }

    const { pegawai_id } = req.body;

    if (!pegawai_id) {
      return res.status(400).json({ message: "Pegawai ID wajib diisi!" });
    }

    // Get work settings
    const [workSettings] = await db.query("SELECT * FROM settings_kerja LIMIT 1");
    const settings = workSettings[0] || {
      jam_masuk_awal: '07:00',
      jam_masuk_akhir: '09:00',
      jam_keluar_awal: '16:00',
      jam_keluar_akhir: '17:00'
    };

    // Get current date & time in Jakarta timezone
    const now = new Date();
    const jakartaDate = new Date(now.toLocaleString("en-US", { timeZone: "Asia/Jakarta" }));
    const todayStr = jakartaDate.toISOString().split('T')[0];
    const jamKeluar = jakartaDate.toTimeString().split(' ')[0];

    // ⏰ CHECK JAM KELUAR AWAL & AKHIR
    const normalizeTime = (t) => t && t.length === 5 ? t + ':00' : (t || '00:00:00');
    
    if (normalizeTime(jamKeluar) < normalizeTime(String(settings.jam_keluar_awal))) {
      return res.status(400).json({ 
        message: `Waktu absen pulang belum dimulai!\n\nJam keluar awal: ${settings.jam_keluar_awal}`,
        dailyLimitExceeded: true
      });
    }

    if (normalizeTime(jamKeluar) > normalizeTime(String(settings.jam_keluar_akhir))) {
      return res.status(400).json({ 
        message: `Waktu absen pulang sudah berakhir!\n\nJam keluar akhir: ${settings.jam_keluar_akhir}`,
        dailyLimitExceeded: true
      });
    }

    // Check if pegawai exists
    const [pegawai] = await db.query(
      "SELECT id, nama FROM pegawai WHERE id = ?",
      [pegawai_id]
    );

    if (pegawai.length === 0) {
      return res.status(404).json({ message: "Pegawai tidak ditemukan!" });
    }

    const pegawaiData = pegawai[0];

    // Check if absensi record exists for today
    const [absensi] = await db.query(
      "SELECT * FROM absensi WHERE pegawai_id = ? AND tanggal = ?",
      [pegawai_id, todayStr]
    );

    if (absensi.length === 0) {
      return res.status(400).json({ 
        message: `${pegawaiData.nama} belum melakukan absensi masuk hari ini!` 
      });
    }

    // Check if already checkout
    const absensiRecord = absensi[0];
    if (absensiRecord.jam_keluar && absensiRecord.jam_keluar !== '17:00') {
      return res.status(400).json({ 
        message: `${pegawaiData.nama} sudah checkout pada ${absensiRecord.jam_keluar}!` 
      });
    }

    // Update jam_keluar
    await db.query(
      "UPDATE absensi SET jam_keluar = ? WHERE id = ?",
      [jamKeluar, absensiRecord.id]
    );

    res.json({
      message: `✅ Checkout berhasil untuk ${pegawaiData.nama} pada ${jamKeluar}!`,
      pegawai_nama: pegawaiData.nama,
      tanggal: todayStr,
      jam_masuk: absensiRecord.jam_masuk,
      jam_keluar: jamKeluar,
      status: "Hadir"
    });
  } catch (err) {
    console.error("Error checkout:", err);
    res.status(500).json({ message: err.message });
  }
});

// ❌ DELETE QR CODE (ADMIN ONLY)
app.delete("/qr-code/:id", verifyToken, checkDbReady, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: "Hanya admin yang dapat menghapus QR Code." });
    }

    const [qrCode] = await db.query("SELECT * FROM qr_codes WHERE id = ?", [req.params.id]);
    
    if (qrCode.length === 0) {
      return res.status(404).json({ message: "QR Code tidak ditemukan." });
    }

    if (qrCode[0].status === 'used') {
      return res.status(400).json({ message: "QR Code yang sudah digunakan tidak dapat dihapus!" });
    }

    await db.query("DELETE FROM qr_codes WHERE id = ?", [req.params.id]);

    res.json({ message: "QR Code berhasil dihapus" });
  } catch (err) {
    console.error("Error deleting QR code:", err);
    res.status(500).json({ message: err.message });
  }
});

// =======================
// 👤 ADMIN DIRECT USER CREATION
// =======================
console.log("🔧 Loading USER CREATION endpoints...");

// ➕ CREATE USER ACCOUNT DIRECTLY (ADMIN ONLY)
app.post("/user/create", verifyToken, checkDbReady, async (req, res) => {
  console.log("📝 /user/create endpoint called!");
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: "Hanya admin yang dapat membuat user." });
    }

    let { username, password, nama, divisi_id, jabatan } = req.body;
    if (username) username = username.trim();
    if (nama) nama = nama.trim();

    // Validasi input
    if (!username || !password || !nama) {
      return res.status(400).json({ message: "Username, password, dan nama wajib diisi!" });
    }

    // Check username sudah ada
    const [existingUser] = await db.query("SELECT * FROM users WHERE username = ?", [username]);
    if (existingUser.length > 0) {
      return res.status(400).json({ message: "Username sudah terdaftar!" });
    }

    // Create pegawai first
    const valDivisiId = divisi_id === "" || divisi_id === undefined || divisi_id === null ? null : divisi_id;
    const [pegawaiResult] = await db.query(
      "INSERT INTO pegawai (nama, divisi_id, jabatan) VALUES (?, ?, ?)",
      [nama, valDivisiId, jabatan || 'Karyawan']
    );

    // Hash password
    const hash = await bcrypt.hash(password, 10);

    // Create user account
    await db.query(
      "INSERT INTO users (username, password, password_raw, role, pegawai_id) VALUES (?, ?, ?, 'user', ?)",
      [username, hash, password, pegawaiResult.insertId]
    );

    res.json({
      message: "User dan data pegawai berhasil dibuat!",
      username,
      nama,
      pegawai_id: pegawaiResult.insertId
    });
  } catch (err) {
    console.error("Error creating user:", err);
    res.status(500).json({ message: err.message });
  }
});

// TEST ENDPOINT
console.log("DEBUG: Registering /test-endpoint");
app.get("/test-endpoint", (req, res) => {
  res.json({ message: "Test endpoint works!" });
});

// =======================
// ⏰ WORK HOURS SETTINGS
// =======================
app.get("/settings", async (req, res) => {
  try {
    const [settings] = await db.query("SELECT * FROM settings_kerja LIMIT 1");
    if (settings.length === 0) {
      return res.status(404).json({ message: "Settings tidak ditemukan" });
    }
    res.json(settings[0]);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

app.put("/settings", verifyToken, checkDbReady, async (req, res) => {
  try {
    // Admin only
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: "Hanya admin yang dapat mengubah pengaturan!" });
    }

    const { jam_masuk_awal, jam_masuk_akhir, jam_keluar_awal, jam_keluar_akhir } = req.body;

    // Validate time format (HH:MM)
    const timeRegex = /^([0-1][0-9]|2[0-3]):[0-5][0-9]$/;
    if (!(timeRegex.test(jam_masuk_awal) && timeRegex.test(jam_masuk_akhir) && 
          timeRegex.test(jam_keluar_awal) && timeRegex.test(jam_keluar_akhir))) {
      return res.status(400).json({ message: "Format waktu harus HH:MM (contoh: 08:00)" });
    }

    await db.query(
      "UPDATE settings_kerja SET jam_masuk_awal = ?, jam_masuk_akhir = ?, jam_keluar_awal = ?, jam_keluar_akhir = ? WHERE id = 1",
      [jam_masuk_awal, jam_masuk_akhir, jam_keluar_awal, jam_keluar_akhir]
    );

    res.json({
      message: "Pengaturan jam kerja berhasil diperbarui!",
      settings: {
        jam_masuk_awal,
        jam_masuk_akhir,
        jam_keluar_awal,
        jam_keluar_akhir
      }
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// =======================
// 404 HANDLER - MUST BE LAST!
// =======================
app.use((req, res) => {
  res.status(404).json({ message: "Route tidak ditemukan" });
});

// =======================
// 🚀 START SERVER
// =======================
(async () => {
  const dbReady = await initializeDatabase();
  
  if (dbReady) {
    app.listen(5000, () => {
      console.log("Server jalan di http://localhost:5000 ✅");
    });
  } else {
    console.error("❌ Server gagal start karena database initialization gagal");
    process.exit(1);
  }
})();
