const mysql = require('mysql2');

const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '', // kalau XAMPP biasanya kosong
    database: 'absensi_qr'
});

db.connect((err) => {
    if (err) {
        console.log('Koneksi gagal:', err);
    } else {
        console.log('Database terkoneksi');
    }
});

module.exports = db;