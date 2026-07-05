// =======================
// IMPORT MODULE
// =======================
console.log("🔧 index.js file is loading...");
const express = require("express");
const mysql = require("mysql2/promise");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const cors = require("cors");

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

    // Migrasi kolom tambahan tabel absensi
    try {
      await db.query("ALTER TABLE absensi ADD COLUMN alasan TEXT NULL");
      console.log("Column 'alasan' added to absensi ⚙️");
    } catch (e) {}
    try {
      await db.query("ALTER TABLE absensi ADD COLUMN foto_bukti LONGTEXT NULL");
      console.log("Column 'foto_bukti' added to absensi ⚙️");
    } catch (e) {}

    // Migrasi kolom tambahan tabel pegawai
    try {
      await db.query("ALTER TABLE pegawai ADD COLUMN foto LONGTEXT NULL");
      console.log("Column 'foto' added to pegawai ⚙️");
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

    console.log("Struktur tabel siap & terverifikasi 📁");

    // 5. Seeding Data Default
    // A. Seed User & Pegawai (admin & budi) jika kosong
    const [userCount] = await db.query("SELECT COUNT(*) as count FROM users");
    if (userCount[0].count === 0) {
      const adminHash = await bcrypt.hash("123456", 10);
      const budiHash = await bcrypt.hash("123456", 10);
      
      // Buat pegawai admin terlebih dahulu
      const [adminPegawai] = await db.query(
        "INSERT INTO pegawai (nama, jabatan) VALUES (?, ?)", 
        ["admin", "Administrator"]
      );
      
      // Buat pegawai budi
      const [budiPegawai] = await db.query(
        "INSERT INTO pegawai (nama, jabatan) VALUES (?, ?)", 
        ["budi", "Karyawan"]
      );
      
      // Buat user admin dengan pegawai_id
      await db.query(
        "INSERT INTO users (username, password, password_raw, role, pegawai_id) VALUES (?, ?, ?, ?, ?)", 
        ["admin", adminHash, "123456", "admin", adminPegawai.insertId]
      );
      
      // Buat user budi dengan pegawai_id
      await db.query(
        "INSERT INTO users (username, password, password_raw, role, pegawai_id) VALUES (?, ?, ?, ?, ?)", 
        ["budi", budiHash, "123456", "user", budiPegawai.insertId]
      );
      
      console.log("🌱 Seeded default users with pegawai: admin/123456 & budi/123456");
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
    const axios = require("axios");
    
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
    const axios = require("axios");
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

    // Hapus user terkait agar tidak bisa login lagi
    await db.query("DELETE FROM users WHERE pegawai_id = ?", [req.params.id]);

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
        pegawai.nama,
        absensi.tanggal,
        absensi.status,
        absensi.alasan,
        absensi.foto_bukti
      FROM absensi
      JOIN pegawai ON absensi.pegawai_id = pegawai.id
    `);

    res.json({ data: rows });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// =======================
// ➕ TAMBAH ABSENSI (ENFORCE 7 DAYS SAKIT/IZIN LIMIT & SUPPORT RANGES)
// =======================
app.post("/absensi", verifyToken, checkDbReady, async (req, res) => {
  try {
    const { pegawai_id, tanggal, tanggal_mulai, tanggal_selesai, jam_masuk, jam_keluar, status, alasan, foto_bukti } = req.body;

    const startStr = tanggal_mulai || tanggal;
    const endStr = tanggal_selesai || tanggal;

    if (!startStr || !endStr) {
      return res.status(400).json({ message: "Tanggal tidak boleh kosong" });
    }

    const start = new Date(startStr);
    const end = new Date(endStr);
    const dateList = [];
    for (let d = new Date(start); d <= end; d.setDate(d.getDate() + 1)) {
      dateList.push(d.toISOString().split('T')[0]);
    }

    // Check if status is Sakit or Izin
    if (status === "Sakit" || status === "Izin") {
      // 1. Hitung jumlah sakit/izin yang sudah diambil sebelumnya
      const [leaves] = await db.query(
        "SELECT COUNT(*) as count FROM absensi WHERE pegawai_id = ? AND (status = 'Sakit' OR status = 'Izin')",
        [pegawai_id]
      );
      const leaveCount = leaves[0].count;

      // 2. Hitung jumlah cuti tambahan yang disetujui (Approved)
      const [approvedCuti] = await db.query(
        "SELECT SUM(durasi_hari) as total FROM cuti_tambahan WHERE pegawai_id = ? AND status = 'Disetujui'",
        [pegawai_id]
      );
      const additionalQuota = approvedCuti[0].total || 0;

      // 3. Batas total adalah 7 + kuota tambahan
      const maxAllowed = 7 + parseInt(additionalQuota);

      if (leaveCount + dateList.length > maxAllowed) {
        // If single day from simulator/QR, mark as Alpa
        if (dateList.length === 1 && !tanggal_mulai) {
          const [result] = await db.query(
            `INSERT INTO absensi 
            (pegawai_id, tanggal, jam_masuk, jam_keluar, status, alasan, foto_bukti)
            VALUES (?, ?, ?, ?, 'Alpa', ?, ?)`,
            [pegawai_id, dateList[0], jam_masuk || '08:00', jam_keluar || '17:00', alasan || null, foto_bukti || null]
          );

          return res.json({
            message: "Jatah Izin/Sakit Anda habis! Presensi dicatat otomatis sebagai ALPA. Silakan ajukan Cuti Tambahan.",
            id: result.insertId,
            limitExceeded: true
          });
        } else {
          // If range, return hard block error
          return res.status(400).json({
            message: "Jatah Izin/Sakit tidak mencukupi untuk durasi yang diajukan!",
            limitExceeded: true
          });
        }
      }
    }

    // Insert absensi normal / range
    let lastInsertId = null;
    for (const dt of dateList) {
      const [result] = await db.query(
        `INSERT INTO absensi 
        (pegawai_id, tanggal, jam_masuk, jam_keluar, status, alasan, foto_bukti)
        VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [pegawai_id, dt, jam_masuk || '08:00', jam_keluar || '17:00', status, alasan || null, foto_bukti || null]
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

// =======================
// GET KETIDAKHADIRAN (TIDAK HADIR) UNTUK HARI INI
// =======================
app.get("/ketidakhadiran", verifyToken, checkDbReady, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: "Hanya admin yang dapat melihat data ketidakhadiran." });
    }

    // Ambil parameter tanggal dari query, default hari ini
    const queryDate = req.query.tanggal || new Date().toISOString().split('T')[0];
    
    // Dapatkan semua pegawai
    const [allPegawai] = await db.query(`
      SELECT id, nama, jabatan, divisi_id, foto 
      FROM pegawai 
      ORDER BY nama ASC
    `);

    // Dapatkan semua yang sudah absen hari ini
    const [hadir] = await db.query(`
      SELECT DISTINCT pegawai_id 
      FROM absensi 
      WHERE tanggal = ?
    `, [queryDate]);

    const hadirIds = new Set(hadir.map(h => h.pegawai_id));

    // Dapatkan semua yang punya cuti disetujui pada tanggal ini
    const [cutiDiajukan] = await db.query(`
      SELECT DISTINCT pegawai_id 
      FROM cuti_tambahan 
      WHERE status = 'Disetujui' 
      AND tanggal_mulai <= ? 
      AND tanggal_selesai >= ?
    `, [queryDate, queryDate]);

    const cutiIds = new Set(cutiDiajukan.map(c => c.pegawai_id));

    // Filter pegawai yang tidak hadir dan tidak punya cuti disetujui
    const tidakHadir = allPegawai
      .filter(p => !hadirIds.has(p.id) && !cutiIds.has(p.id))
      .map(p => ({
        id: p.id,
        nama: p.nama,
        jabatan: p.jabatan,
        divisi_id: p.divisi_id,
        foto: p.foto,
        status: 'Tidak Hadir'
      }));

    res.json({
      tanggal: queryDate,
      total_tidak_hadir: tidakHadir.length,
      data: tidakHadir
    });
  } catch (err) {
    console.error("Error fetching ketidakhadiran:", err);
    res.status(500).json({ message: err.message });
  }
});

// =======================
// GET CUTI TAMBAHAN
// =======================
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
// ➕ AJUKAN CUTI TAMBAHAN
// =======================
app.post("/cuti", verifyToken, checkDbReady, async (req, res) => {
  try {
    const { pegawai_id, tanggal_mulai, tanggal_selesai, keperluan, alasan, foto_bukti } = req.body;
    
    if (!tanggal_mulai || !tanggal_selesai) {
      return res.status(400).json({ message: "Tanggal mulai dan selesai harus diisi" });
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
// ✏️ UPDATE STATUS CUTI (ACC ADMIN)
// =======================
app.put("/cuti/:id", verifyToken, checkDbReady, async (req, res) => {
  try {
    const { status } = req.body; // 'Disetujui' atau 'Ditolak'

    await db.query(
      "UPDATE cuti_tambahan SET status = ? WHERE id = ?",
      [status, req.params.id]
    );

    res.json({ message: `Pengajuan cuti telah ${status}` });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

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

    // Check if user owns this QR code
    const [user] = await db.query("SELECT pegawai_id FROM users WHERE id = ?", [req.user.id]);
    if (!user || !user[0] || user[0].pegawai_id !== qrData.pegawai_id) {
      return res.status(403).json({ message: "QR Code ini bukan milik Anda!" });
    }

    // Get current date in Jakarta timezone
    const jakartaDate = new Date(now.toLocaleString("en-US", { timeZone: "Asia/Jakarta" }));
    const todayStr = jakartaDate.toISOString().split('T')[0];

    // Check if already absent today
    const [existingAbsensi] = await db.query(
      "SELECT * FROM absensi WHERE pegawai_id = ? AND tanggal = ?",
      [qrData.pegawai_id, todayStr]
    );

    if (existingAbsensi.length > 0) {
      return res.status(400).json({ message: "Anda sudah absen hari ini!" });
    }

    // Insert attendance record
    const jamMasuk = jakartaDate.toTimeString().split(' ')[0];
    const [absensiResult] = await db.query(
      "INSERT INTO absensi (pegawai_id, tanggal, jam_masuk, status) VALUES (?, ?, ?, 'Hadir')",
      [qrData.pegawai_id, todayStr, jamMasuk]
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
app.get("/test-endpoint", (req, res) => {
  res.json({ message: "Test endpoint works!" });
});

// KETIDAKHADIRAN DUMMY ENDPOINT
app.get("/ketidakhadiran-test", (req, res) => {
  res.json({ message: "Ketidakhadiran endpoint exists!" });
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
