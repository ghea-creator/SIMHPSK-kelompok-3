const mysql = require("mysql2/promise");

async function consolidateDatabase() {
  let db;
  try {
    db = await mysql.createConnection({
      host: "localhost",
      user: "root",
      password: "",
      database: "absensi_qr"
    });

    console.log("🔄 Memulai consolidasi database (gabung users + pegawai)...\n");

    // Step 1: Tambah kolom ke users jika belum ada
    console.log("Step 1️⃣  Menambah kolom ke table users...");
    try {
      await db.query(`
        ALTER TABLE users 
        ADD COLUMN nama VARCHAR(255),
        ADD COLUMN divisi_id INT,
        ADD COLUMN jabatan VARCHAR(255)
      `);
      console.log("✅ Kolom berhasil ditambahkan\n");
    } catch (err) {
      if (err.code === 'ER_DUP_FIELDNAME') {
        console.log("ℹ️  Kolom sudah ada, melanjutkan...\n");
      } else {
        throw err;
      }
    }

    // Step 2: Copy data dari pegawai ke users (untuk user yang sudah punya pegawai_id)
    console.log("Step 2️⃣  Copy data dari pegawai ke users...");
    
    // Update users yang punya pegawai_id
    await db.query(`
      UPDATE users u
      INNER JOIN pegawai p ON u.pegawai_id = p.id
      SET u.nama = p.nama, 
          u.divisi_id = p.divisi_id, 
          u.jabatan = p.jabatan
      WHERE u.pegawai_id IS NOT NULL
    `);
    console.log("✅ Data berhasil dicopy\n");

    // Step 3: Update relasi di tabel absensi (dari pegawai_id ke user_id)
    console.log("Step 3️⃣  Update relasi di tabel absensi...");
    try {
      // Cek struktur absensi dulu
      const [absensiColumns] = await db.query(`SHOW COLUMNS FROM absensi`);
      const hasUserId = absensiColumns.some(col => col.Field === 'user_id');
      
      if (!hasUserId) {
        // Drop foreign key lama jika ada
        try {
          await db.query(`ALTER TABLE absensi DROP FOREIGN KEY absensi_ibfk_1`);
        } catch (e) {
          // Key mungkin tidak ada, skip
        }
        
        // Ubah pegawai_id menjadi user_id
        await db.query(`
          ALTER TABLE absensi 
          CHANGE COLUMN pegawai_id user_id INT,
          ADD FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        `);
      }
      console.log("✅ Relasi absensi berhasil diupdate\n");
    } catch (err) {
      console.log("⚠️  Catatan absensi:", err.message);
    }

    // Step 4: Update relasi di tabel cuti_tambahan (dari pegawai_id ke user_id)
    console.log("Step 4️⃣  Update relasi di tabel cuti_tambahan...");
    try {
      const [cutiColumns] = await db.query(`SHOW COLUMNS FROM cuti_tambahan`);
      const hasUserId = cutiColumns.some(col => col.Field === 'user_id');
      
      if (!hasUserId) {
        // Drop foreign key lama jika ada
        try {
          await db.query(`ALTER TABLE cuti_tambahan DROP FOREIGN KEY cuti_tambahan_ibfk_1`);
        } catch (e) {
          // Key mungkin tidak ada, skip
        }
        
        // Ubah pegawai_id menjadi user_id
        await db.query(`
          ALTER TABLE cuti_tambahan 
          CHANGE COLUMN pegawai_id user_id INT,
          ADD FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        `);
      }
      console.log("✅ Relasi cuti_tambahan berhasil diupdate\n");
    } catch (err) {
      console.log("⚠️  Catatan cuti_tambahan:", err.message);
    }

    // Step 5: Drop tabel pegawai
    console.log("Step 5️⃣  Menghapus tabel pegawai (sudah tidak diperlukan)...");
    try {
      await db.query(`DROP TABLE pegawai`);
      console.log("✅ Tabel pegawai berhasil dihapus\n");
    } catch (err) {
      console.log("⚠️  Catatan:", err.message);
    }

    // Step 6: Verifikasi hasil
    console.log("Step 6️⃣  Verifikasi struktur database baru...\n");
    
    const [users] = await db.query(`
      SELECT id, username, role, nama, divisi_id, jabatan 
      FROM users
    `);

    console.log("📋 Data users (sekarang termasuk info pegawai):\n");
    users.forEach(user => {
      console.log(`  ID: ${user.id}`);
      console.log(`  Username: ${user.username}`);
      console.log(`  Nama: ${user.nama || '-'}`);
      console.log(`  Role: ${user.role}`);
      console.log(`  Divisi ID: ${user.divisi_id || '-'}`);
      console.log(`  Jabatan: ${user.jabatan || '-'}`);
      console.log();
    });

    const [tables] = await db.query(`SHOW TABLES FROM absensi_qr`);
    console.log("📊 Tabel yang tersisa:", tables.map(t => Object.values(t)[0]).join(', '));

    console.log("\n✨ Consolidasi database berhasil!");

  } catch (err) {
    console.error("❌ Error saat consolidasi:", err.message);
    console.error(err);
  } finally {
    if (db) await db.end();
  }
}

consolidateDatabase();
