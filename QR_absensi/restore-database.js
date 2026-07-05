const mysql = require("mysql2/promise");

async function restoreDatabase() {
  let conn;
  try {
    conn = await mysql.createConnection({
      host: "localhost",
      user: "root",
      password: "",
      database: "absensi_qr"
    });

    console.log("🔄 Memulai pemulihan database (mengembalikan table pegawai)...\n");

    // Disable foreign key checks
    await conn.query("SET FOREIGN_KEY_CHECKS = 0");
    console.log("⚠️  Foreign key checks dimatikan sementara");

    // 1. Re-create Table Pegawai if not exists
    console.log("Step 1️⃣  Memastikan table pegawai ada...");
    await conn.query(`
      CREATE TABLE IF NOT EXISTS pegawai (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nama VARCHAR(255) NOT NULL,
        divisi_id INT,
        jabatan VARCHAR(255) NOT NULL,
        FOREIGN KEY (divisi_id) REFERENCES divisi(id) ON DELETE SET NULL
      )
    `);
    console.log("✅ Table pegawai terverifikasi");

    // 2. Ensure columns in users, absensi, cuti_tambahan
    console.log("Step 2️⃣  Menambahkan kolom pegawai_id ke tabel users, absensi, dan cuti_tambahan...");
    
    // check users column pegawai_id
    const [usersCols] = await conn.query("SHOW COLUMNS FROM users LIKE 'pegawai_id'");
    if (usersCols.length === 0) {
      await conn.query("ALTER TABLE users ADD COLUMN pegawai_id INT NULL");
      console.log("  ✅ Kolom pegawai_id ditambahkan ke users");
    }

    // check absensi column pegawai_id
    const [absensiCols] = await conn.query("SHOW COLUMNS FROM absensi LIKE 'pegawai_id'");
    if (absensiCols.length === 0) {
      await conn.query("ALTER TABLE absensi ADD COLUMN pegawai_id INT NULL");
      console.log("  ✅ Kolom pegawai_id ditambahkan ke absensi");
    }

    // check cuti_tambahan column pegawai_id
    const [cutiCols] = await conn.query("SHOW COLUMNS FROM cuti_tambahan LIKE 'pegawai_id'");
    if (cutiCols.length === 0) {
      await conn.query("ALTER TABLE cuti_tambahan ADD COLUMN pegawai_id INT NULL");
      console.log("  ✅ Kolom pegawai_id ditambahkan ke cuti_tambahan");
    }

    // 3. Get all users
    const [users] = await conn.query("SELECT * FROM users");
    console.log(`\nStep 3️⃣  Membaca ${users.length} pengguna dari database:`);

    for (const user of users) {
      // Periksa apakah pegawai untuk user ini sudah ada di tabel pegawai
      const [existingPegawai] = await conn.query("SELECT id FROM pegawai WHERE nama = ?", [user.nama || user.username]);
      
      let pId;
      if (existingPegawai.length > 0) {
        pId = existingPegawai[0].id;
        console.log(`  ℹ️  Pegawai untuk user ${user.username} sudah ada (ID: ${pId})`);
      } else {
        // Buat pegawai baru
        const namaPegawai = user.nama || user.username;
        const jabatanPegawai = user.jabatan || (user.role === "admin" ? "Administrator" : "Karyawan");
        const divisiId = user.divisi_id;

        const [resInsert] = await conn.query(
          "INSERT INTO pegawai (nama, divisi_id, jabatan) VALUES (?, ?, ?)",
          [namaPegawai, divisiId, jabatanPegawai]
        );
        pId = resInsert.insertId;
        console.log(`  ✅ Pegawai baru dibuat untuk user ${user.username} (ID Pegawai: ${pId})`);
      }

      // Hubungkan user ke pegawai
      await conn.query("UPDATE users SET pegawai_id = ? WHERE id = ?", [pId, user.id]);

      // Map absensi records if any (using user_id column)
      const [absensiUserCols] = await conn.query("SHOW COLUMNS FROM absensi LIKE 'user_id'");
      if (absensiUserCols.length > 0) {
        const [updateRes] = await conn.query("UPDATE absensi SET pegawai_id = ? WHERE user_id = ?", [pId, user.id]);
        if (updateRes.affectedRows > 0) {
          console.log(`  ✅ ${updateRes.affectedRows} log absensi dihubungkan ke pegawai baru (ID: ${pId})`);
        }
      }

      // Map cuti_tambahan records if any (using user_id column)
      const [cutiUserCols] = await conn.query("SHOW COLUMNS FROM cuti_tambahan LIKE 'user_id'");
      if (cutiUserCols.length > 0) {
        const [updateRes] = await conn.query("UPDATE cuti_tambahan SET pegawai_id = ? WHERE user_id = ?", [pId, user.id]);
        if (updateRes.affectedRows > 0) {
          console.log(`  ✅ ${updateRes.affectedRows} pengajuan cuti dihubungkan ke pegawai baru (ID: ${pId})`);
        }
      }
    }

    // 4. Drop user_id columns if they exist
    console.log("\nStep 4️⃣  Menghapus kolom user_id (kolom temporer dari consolidasi) jika ada...");
    try {
      const [absCols] = await conn.query("SHOW COLUMNS FROM absensi LIKE 'user_id'");
      if (absCols.length > 0) {
        await conn.query("ALTER TABLE absensi DROP FOREIGN KEY absensi_user_fk");
      }
    } catch(e) {}
    try {
      const [absCols] = await conn.query("SHOW COLUMNS FROM absensi LIKE 'user_id'");
      if (absCols.length > 0) {
        await conn.query("ALTER TABLE absensi DROP COLUMN user_id");
        console.log("  ✅ Kolom user_id di tabel absensi dihapus");
      }
    } catch(e) {
      console.log("  ⚠️  Gagal drop absensi.user_id:", e.message);
    }

    try {
      const [cutiCols] = await conn.query("SHOW COLUMNS FROM cuti_tambahan LIKE 'user_id'");
      if (cutiCols.length > 0) {
        await conn.query("ALTER TABLE cuti_tambahan DROP FOREIGN KEY cuti_user_fk");
      }
    } catch(e) {}
    try {
      const [cutiCols] = await conn.query("SHOW COLUMNS FROM cuti_tambahan LIKE 'user_id'");
      if (cutiCols.length > 0) {
        await conn.query("ALTER TABLE cuti_tambahan DROP COLUMN user_id");
        console.log("  ✅ Kolom user_id di tabel cuti_tambahan dihapus");
      }
    } catch(e) {
      console.log("  ⚠️  Gagal drop cuti_tambahan.user_id:", e.message);
    }

    // 5. Clean up duplicate foreign keys/constraints and rebuild
    console.log("\nStep 5️⃣  Menghapus foreign key lama dan membuat yang baru...");
    const dropFk = async (table, fk) => {
      try {
        await conn.query(`ALTER TABLE ${table} DROP FOREIGN KEY ${fk}`);
        console.log(`  ✅ Foreign key ${fk} pada ${table} berhasil dihapus`);
      } catch (e) {}
    };

    await dropFk("users", "users_ibfk_1");
    await dropFk("absensi", "absensi_ibfk_1");
    await dropFk("absensi", "absensi_user_fk");
    await dropFk("cuti_tambahan", "cuti_tambahan_ibfk_1");
    await dropFk("cuti_tambahan", "cuti_user_fk");

    // Add constraints
    try {
      await conn.query(`
        ALTER TABLE users 
        ADD CONSTRAINT fk_users_pegawai 
        FOREIGN KEY (pegawai_id) REFERENCES pegawai(id) ON DELETE SET NULL
      `);
      console.log("  ✅ Foreign key users.pegawai_id -> pegawai.id dibuat");
    } catch (e) {
      console.log("  ℹ️  Foreign key users.pegawai_id sudah ada atau gagal dibuat:", e.message);
    }

    try {
      await conn.query(`
        ALTER TABLE absensi 
        ADD CONSTRAINT fk_absensi_pegawai 
        FOREIGN KEY (pegawai_id) REFERENCES pegawai(id) ON DELETE CASCADE
      `);
      console.log("  ✅ Foreign key absensi.pegawai_id -> pegawai.id dibuat");
    } catch (e) {
      console.log("  ℹ️  Foreign key absensi.pegawai_id sudah ada atau gagal dibuat:", e.message);
    }

    try {
      await conn.query(`
        ALTER TABLE cuti_tambahan 
        ADD CONSTRAINT fk_cuti_pegawai 
        FOREIGN KEY (pegawai_id) REFERENCES pegawai(id) ON DELETE CASCADE
      `);
      console.log("  ✅ Foreign key cuti_tambahan.pegawai_id -> pegawai.id dibuat");
    } catch (e) {
      console.log("  ℹ️  Foreign key cuti_tambahan.pegawai_id sudah ada atau gagal dibuat:", e.message);
    }

    // Enable foreign key checks
    await conn.query("SET FOREIGN_KEY_CHECKS = 1");
    console.log("\n✅ Foreign key checks diaktifkan kembali");
    console.log("✨ Pemulihan database selesai!");

  } catch (err) {
    console.error("❌ Error:", err.message);
  } finally {
    if (conn) await conn.end();
  }
}

restoreDatabase();
