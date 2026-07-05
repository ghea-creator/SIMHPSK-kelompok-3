// Reset database - drop semua tables dan reinitialize
const mysql = require("mysql2/promise");
const bcrypt = require("bcryptjs");

(async () => {
  try {
    console.log('🔄 Starting database reset...');
    
    const conn = await mysql.createConnection({
      host: "localhost",
      user: "root",
      password: "",
      database: "absensi_qr",
    });
    
    console.log('Connected to database');
    
    // Drop all tables
    console.log('Dropping existing tables...');
    await conn.query('DROP TABLE IF EXISTS absensi');
    await conn.query('DROP TABLE IF EXISTS cuti_tambahan');
    await conn.query('DROP TABLE IF EXISTS users');
    await conn.query('DROP TABLE IF EXISTS pegawai');
    await conn.query('DROP TABLE IF EXISTS divisi');
    
    console.log('✅ Tables dropped');
    
    // Create tables
    console.log('Creating tables...');
    
    // Tabel Divisi
    await conn.query(`
      CREATE TABLE divisi (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nama_divisi VARCHAR(255) NOT NULL
      )
    `);
    console.log('✅ Divisi table created');
    
    // Tabel Pegawai
    await conn.query(`
      CREATE TABLE pegawai (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nama VARCHAR(255) NOT NULL,
        divisi_id INT,
        jabatan VARCHAR(255) NOT NULL,
        FOREIGN KEY (divisi_id) REFERENCES divisi(id) ON DELETE SET NULL
      )
    `);
    console.log('✅ Pegawai table created');
    
    // Tabel Users
    await conn.query(`
      CREATE TABLE users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(255) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        role VARCHAR(50) NOT NULL DEFAULT 'user',
        pegawai_id INT NULL,
        FOREIGN KEY (pegawai_id) REFERENCES pegawai(id) ON DELETE SET NULL
      )
    `);
    console.log('✅ Users table created');
    
    // Tabel Absensi
    await conn.query(`
      CREATE TABLE absensi (
        id INT AUTO_INCREMENT PRIMARY KEY,
        pegawai_id INT,
        tanggal DATE NOT NULL,
        jam_masuk TIME,
        jam_keluar TIME,
        status VARCHAR(50),
        alasan TEXT NULL,
        foto_bukti LONGTEXT NULL,
        FOREIGN KEY (pegawai_id) REFERENCES pegawai(id) ON DELETE CASCADE
      )
    `);
    console.log('✅ Absensi table created');
    
    // Tabel Cuti Tambahan
    await conn.query(`
      CREATE TABLE cuti_tambahan (
        id INT AUTO_INCREMENT PRIMARY KEY,
        pegawai_id INT NOT NULL,
        tanggal_pengajuan DATE NOT NULL,
        alasan TEXT,
        durasi_hari INT NOT NULL,
        status VARCHAR(50) NOT NULL DEFAULT 'Pending',
        tanggal_mulai DATE NULL,
        tanggal_selesai DATE NULL,
        keperluan VARCHAR(255) NULL,
        foto_bukti LONGTEXT NULL,
        FOREIGN KEY (pegawai_id) REFERENCES pegawai(id) ON DELETE CASCADE
      )
    `);
    console.log('✅ Cuti_tambahan table created');
    
    // Seed data
    console.log('Seeding default data...');
    
    const adminHash = await bcrypt.hash("123456", 10);
    const budiHash = await bcrypt.hash("123456", 10);
    
    // Insert divisi
    await conn.query("INSERT INTO divisi (nama_divisi) VALUES ('IT'), ('HRD'), ('Finance'), ('Marketing')");
    console.log('✅ Divisi seeded');
    
    // Insert pegawai admin
    const [adminPegawaiResult] = await conn.query(
      "INSERT INTO pegawai (nama, jabatan) VALUES (?, ?)", 
      ["admin", "Administrator"]
    );
    
    // Insert pegawai budi
    const [budiPegawaiResult] = await conn.query(
      "INSERT INTO pegawai (nama, jabatan) VALUES (?, ?)", 
      ["budi", "Karyawan"]
    );
    
    // Insert users
    await conn.query(
      "INSERT INTO users (username, password, role, pegawai_id) VALUES (?, ?, ?, ?)", 
      ["admin", adminHash, "admin", adminPegawaiResult.insertId]
    );
    
    await conn.query(
      "INSERT INTO users (username, password, role, pegawai_id) VALUES (?, ?, ?, ?)", 
      ["budi", budiHash, "user", budiPegawaiResult.insertId]
    );
    
    console.log('✅ Users seeded');
    
    await conn.end();
    console.log('✅ Database reset completed!');
    console.log('Default login: admin / 123456 or budi / 123456');
  } catch (err) {
    console.error('❌ Error:', err.message);
    console.error('Full error:', err);
  }
})();
