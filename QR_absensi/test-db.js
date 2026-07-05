// Test database connection
const mysql = require("mysql2/promise");

(async () => {
  try {
    console.log('Testing MySQL connection...');
    
    const connection = await mysql.createConnection({
      host: "localhost",
      user: "root",
      password: "",
    });
    
    console.log('✅ Connected to MySQL');
    
    const [result] = await connection.query("SELECT 1 as test");
    console.log('✅ Test query successful:', result);
    
    await connection.end();
    console.log('✅ Connection closed');
  } catch (err) {
    console.error('❌ Error:', err.message);
    console.error('Full error:', err);
  }
})();
