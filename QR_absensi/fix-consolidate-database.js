const mysql = require("mysql2/promise");

async function fixConsolidateDatabase() {
  let db;
  try {
    db = await mysql.createConnection({
      host: "localhost",
      user: "root",
      password: "",
      database: "absensi_qr"
    });

    console.log("🔧 Memperbaiki consolidasi database...\n");

    // Step 1: Drop semua foreign key yang bermasalah
    console.log("Step 1️⃣  Menghapus foreign key yang bermasalah...");
    
    try {
      await db.query(`ALTER TABLE users DROP FOREIGN KEY users_ibfk_1`);
      console.log("  ✅ Foreign key users_ibfk_1 dihapus");
    } catch (e) {
      console.log("  ℹ️  Foreign key users_ibfk_1 tidak ada");
    }

    try {
      await db.query(`ALTER TABLE absensi DROP FOREIGN KEY absensi_ibfk_1`);
      console.log("  ✅ Foreign key absensi_ibfk_1 dihapus");
    } catch (e) {
      console.log("  ℹ️  Foreign key absensi_ibfk_1 tidak ada");
    }

    try {
      await db.query(`ALTER TABLE cuti_tambahan DROP FOREIGN KEY cuti_tambahan_ibfk_1`);
      console.log("  ✅ Foreign key cuti_tambahan_ibfk_1 dihapus");
    } catch (e) {
      console.log("  ℹ️  Foreign key cuti_tambahan_ibfk_1 tidak ada");
    }

    console.log();

    // Step 2: Ubah kolom pegawai_id menjadi user_id di absensi dan cuti_tambahan
    console.log("Step 2️⃣  Update struktur tabel relasi...");
    
    // Cek apakah kolom sudah user_id
    const [absensiCols] = await db.query(`SHOW COLUMNS FROM absensi WHERE Field = 'user_id'`);
    if (absensiCols.length === 0) {
      await db.query(`ALTER TABLE absensi CHANGE COLUMN pegawai_id user_id INT`);
      console.log("  ✅ absensi.pegawai_id dirubah menjadi user_id");
    } else {
      console.log("  ℹ️  absensi.user_id sudah ada");
    }

    const [cutiCols] = await db.query(`SHOW COLUMNS FROM cuti_tambahan WHERE Field = 'user_id'`);
    if (cutiCols.length === 0) {
      await db.query(`ALTER TABLE cuti_tambahan CHANGE COLUMN pegawai_id user_id INT`);
      console.log("  ✅ cuti_tambahan.pegawai_id dirubah menjadi user_id");
    } else {
      console.log("  ℹ️  cuti_tambahan.user_id sudah ada");
    }

    console.log();

    // Step 3: Hapus kolom pegawai_id dari users
    console.log("Step 3️⃣  Hapus kolom pegawai_id dari users...");
    try {
      await db.query(`ALTER TABLE users DROP COLUMN pegawai_id`);
      console.log("  ✅ Kolom pegawai_id dihapus\n");
    } catch (e) {
      console.log("  ℹ️  Kolom pegawai_id sudah tidak ada\n");
    }

    // Step 4: Hapus tabel pegawai
    console.log("Step 4️⃣  Menghapus tabel pegawai...");
    try {
      await db.query(`DROP TABLE pegawai`);
      console.log("  ✅ Tabel pegawai dihapus\n");
    } catch (e) {
      console.log("  ⚠️  Error:", e.message, "\n");
    }

    // Step 5: Recreate foreign keys dengan struktur baru
    console.log("Step 5️⃣  Membuat foreign key baru...");
    try {
      await db.query(`
        ALTER TABLE absensi 
        ADD CONSTRAINT absensi_user_fk 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      `);
      console.log("  ✅ Foreign key absensi.user_id dibuat");
    } catch (e) {
      console.log("  ⚠️  Error:", e.message);
    }

    try {
      await db.query(`
        ALTER TABLE cuti_tambahan 
        ADD CONSTRAINT cuti_user_fk 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      `);
      console.log("  ✅ Foreign key cuti_tambahan.user_id dibuat");
    } catch (e) {
      console.log("  ⚠️  Error:", e.message);
    }

    console.log();

    // Step 6: Verifikasi final
    console.log("Step 6️⃣  Verifikasi final...\n");
    
    const [users] = await db.query(`
      SELECT id, username, role, nama, divisi_id, jabatan 
      FROM users
      ORDER BY id
    `);

    console.log("📋 Data users (final):\n");
    users.forEach(user => {
      console.log(`  ${user.id}. ${user.username} (${user.nama}) | Role: ${user.role} | Jabatan: ${user.jabatan}`);
    });

    const [tables] = await db.query(`SHOW TABLES FROM absensi_qr`);
    console.log("\n📊 Tabel database:", tables.map(t => Object.values(t)[0]).join(', '));

    console.log("\n✨ Database consolidation complete!");

  } catch (err) {
    console.error("❌ Error:", err.message);
  } finally {
    if (db) await db.end();
  }
}

fixConsolidateDatabase();
