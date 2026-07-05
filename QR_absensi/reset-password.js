const mysql = require("mysql2/promise");
const bcrypt = require("bcryptjs");

async function resetAdminPassword() {
  try {
    const db = await mysql.createConnection({
      host: "localhost",
      user: "root",
      password: "",
      database: "absensi_qr"
    });

    const password = "123456";
    const hash = await bcrypt.hash(password, 10);

    console.log("🔐 Hash yang akan digunakan:", hash);

    await db.query(
      "UPDATE users SET password = ? WHERE username = 'admin'",
      [hash]
    );

    console.log("✅ Password admin berhasil diupdate menjadi: 123456");

    const [rows] = await db.query(
      "SELECT id, username, password FROM users WHERE username = 'admin'"
    );
    console.log("📋 Data di database:", rows[0]);

    await db.end();
  } catch (err) {
    console.error("❌ Error:", err.message);
  }
}

resetAdminPassword();
