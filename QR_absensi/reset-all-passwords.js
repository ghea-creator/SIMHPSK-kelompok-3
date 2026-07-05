const mysql = require("mysql2/promise");
const bcrypt = require("bcryptjs");

async function resetAllPasswords() {
  try {
    const db = await mysql.createConnection({
      host: "localhost",
      user: "root",
      password: "",
      database: "absensi_qr"
    });

    const password = "123456";
    const hash = await bcrypt.hash(password, 10);

    console.log("🔐 Hash yang digunakan:", hash);
    console.log("\n📝 Mereset password untuk opick dan naufal...\n");

    await db.query(
      "UPDATE users SET password = ? WHERE username IN ('opick', 'naufal')",
      [hash]
    );

    console.log("✅ Password opick dan naufal berhasil diupdate ke: 123456");

    const [rows] = await db.query(
      "SELECT id, username, password, role FROM users"
    );
    
    console.log("\n📋 Semua user di database:\n");
    rows.forEach(user => {
      console.log(`  ID: ${user.id} | Username: ${user.username} | Role: ${user.role}`);
      console.log(`  Password Hash: ${user.password}\n`);
    });

    await db.end();
  } catch (err) {
    console.error("❌ Error:", err.message);
  }
}

resetAllPasswords();
