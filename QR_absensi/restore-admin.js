const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');

async function restoreAdmin() {
  const db = await mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'absensi_qr'
  });

  // Cek apakah admin sudah ada di users
  const [users] = await db.query("SELECT * FROM users WHERE username = 'admin'");
  console.log('Admin di tabel users:', users.length > 0 ? 'ADA' : 'TIDAK ADA');

  if (users.length === 0) {
    const hash = await bcrypt.hash('123456', 10);
    await db.query(
      "INSERT INTO users (username, password, password_raw, role, pegawai_id) VALUES (?, ?, ?, ?, ?)",
      ['admin', hash, '123456', 'admin', null]
    );
    console.log('✅ Admin berhasil dibuat ulang!');
    console.log('   Username : admin');
    console.log('   Password : 123456');
    console.log('   Role     : admin');
  } else {
    console.log('Admin sudah ada di tabel users.');
    console.log('Role:', users[0].role);
    console.log('Pegawai_id:', users[0].pegawai_id);
  }

  await db.end();
  console.log('\nSelesai!');
}

restoreAdmin().catch(console.error);
