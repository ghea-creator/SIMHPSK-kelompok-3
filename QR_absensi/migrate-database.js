const mysql = require("mysql2/promise");

async function migrateDatabase() {
  let db;
  try {
    db = await mysql.createConnection({
      host: "localhost",
      user: "root",
      password: "",
      database: "absensi_qr"
    });

    console.log("🔄 Memulai migrasi database...\n");

    // Step 1: Tambah kolom pegawai_id ke table users
    console.log("Step 1️⃣  Menambah kolom pegawai_id ke table users...");
    try {
      await db.query(`
        ALTER TABLE users 
        ADD COLUMN pegawai_id INT,
        ADD FOREIGN KEY (pegawai_id) REFERENCES pegawai(id) ON DELETE SET NULL
      `);
      console.log("✅ Kolom pegawai_id berhasil ditambahkan\n");
    } catch (err) {
      if (err.code === 'ER_DUP_FIELDNAME') {
        console.log("ℹ️  Kolom pegawai_id sudah ada, melanjutkan...\n");
      } else {
        throw err;
      }
    }

    // Step 2: Cek user yang belum punya pegawai
    console.log("Step 2️⃣  Mengecek data user dan pegawai...");
    const [users] = await db.query("SELECT id, username, role, pegawai_id FROM users");
    
    console.log(`Found ${users.length} users\n`);

    // Step 3: Untuk setiap user, buat pegawai jika belum ada
    console.log("Step 3️⃣  Membuat pegawai untuk user yang belum ada...\n");
    
    for (const user of users) {
      if (user.pegawai_id === null) {
        // Cek apakah pegawai dengan nama sama sudah ada
        const [existingPegawai] = await db.query(
          "SELECT id FROM pegawai WHERE nama = ?",
          [user.username]
        );

        let pegawaiId;
        if (existingPegawai.length > 0) {
          pegawaiId = existingPegawai[0].id;
          console.log(`  ℹ️  Pegawai untuk user ${user.username} sudah ada (ID: ${pegawaiId})`);
        } else {
          // Buat pegawai baru
          const [result] = await db.query(
            "INSERT INTO pegawai (nama, jabatan) VALUES (?, ?)",
            [user.username, user.role === 'admin' ? 'Administrator' : 'Karyawan']
          );
          pegawaiId = result.insertId;
          console.log(`  ✅ Pegawai dibuat untuk user ${user.username} (ID: ${pegawaiId})`);
        }

        // Update user dengan pegawai_id
        await db.query(
          "UPDATE users SET pegawai_id = ? WHERE id = ?",
          [pegawaiId, user.id]
        );
        console.log(`  ✅ User ${user.username} terhubung ke pegawai ID: ${pegawaiId}\n`);
      } else {
        console.log(`  ℹ️  User ${user.username} sudah terhubung ke pegawai ID: ${user.pegawai_id}\n`);
      }
    }

    // Step 4: Verifikasi hasil
    console.log("Step 4️⃣  Verifikasi struktur database baru...\n");
    const [verifyUsers] = await db.query(`
      SELECT u.id, u.username, u.role, u.pegawai_id, p.nama, p.jabatan 
      FROM users u 
      LEFT JOIN pegawai p ON u.pegawai_id = p.id
    `);

    console.log("📋 Data hasil migrasi:\n");
    verifyUsers.forEach(row => {
      console.log(`  User: ${row.username} (ID: ${row.id})`);
      console.log(`  Role: ${row.role}`);
      console.log(`  Pegawai: ${row.nama} (ID: ${row.pegawai_id})`);
      console.log(`  Jabatan: ${row.jabatan}`);
      console.log();
    });

    console.log("✨ Migrasi database berhasil!");

  } catch (err) {
    console.error("❌ Error saat migrasi:", err.message);
    console.error(err);
  } finally {
    if (db) await db.end();
  }
}

migrateDatabase();
