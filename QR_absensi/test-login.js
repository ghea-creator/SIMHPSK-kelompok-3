// Quick test untuk login flow
const mysql = require("mysql2/promise");
const bcrypt = require("bcryptjs");

(async () => {
  try {
    console.log('Starting login test...');
    
    // Create connection
    const db = await mysql.createConnection({
      host: "localhost",
      user: "root",
      password: "",
      database: "absensi_qr",
    });
    
    console.log('✅ Connected to database');
    
    // Test query
    const [rows] = await db.query(
      'SELECT * FROM users WHERE username = ?',
      ['admin']
    );
    
    console.log('✅ Query successful');
    console.log('Rows found:', rows.length);
    
    if (rows.length > 0) {
      const user = rows[0];
      console.log('User found:', { id: user.id, username: user.username, role: user.role });
      
      // Test password
      const validPassword = await bcrypt.compare('123456', user.password);
      console.log('Password valid:', validPassword);
    }
    
    await db.end();
    console.log('✅ Test complete');
  } catch (err) {
    console.error('❌ Error:', err.message);
    console.error('Full error:', err);
  }
})();
