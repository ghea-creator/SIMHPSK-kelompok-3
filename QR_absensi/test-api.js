const http = require('http');

// Get valid token from database (admin user)
const mockToken = 'test'; // We'll test without token first

const options = {
  hostname: 'localhost',
  port: 5000,
  path: '/pegawai',
  method: 'GET',
  headers: {
    'Authorization': 'Bearer ' + mockToken
  }
};

const req = http.request(options, (res) => {
  let data = '';
  
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    try {
      const parsed = JSON.parse(data);
      // Show first pegawai with all keys
      if (parsed.data && parsed.data[3]) {
        console.log('Samsul object keys:', Object.keys(parsed.data[3]));
        console.log('Samsul foto field:', parsed.data[3].foto ? 'EXISTS (length: ' + parsed.data[3].foto.length + ')' : 'NULL');
        console.log('Full samsul object:', JSON.stringify(parsed.data[3], null, 2).substring(0, 300));
      }
    } catch (e) {
      console.log('Raw response:', data.substring(0, 200));
    }
  });
});

req.on('error', (e) => {
  console.error(`Problem with request: ${e.message}`);
});

req.end();
