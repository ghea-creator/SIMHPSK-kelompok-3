// Fix script untuk index.js - hapus character encoding issue
const fs = require('fs');

const filePath = './index.js';
let content = fs.readFileSync(filePath, 'utf-8');

// Replace problematic emoji comments
content = content.replace(/\/\/ =======================\s*\/\/ 📂 GET CUTI TAMBAHAN\s*\/\/ =======================/g, '// GET CUTI TAMBAHAN');

// Replace other bad character comments
content = content.replace(/\/\/ 🚀 RUN SERVER\s*\/\/ =======================\s*\/\/ Tunggu database/g, '// START SERVER\n// Tunggu database');

// Remove stray emoji comments that might break parsing
content = content.replace(/\/\/ 📋/g, '// ');
content = content.replace(/\/\/ 🎫/g, '// ');
content = content.replace(/\/\/ ➕/g, '// ');
content = content.replace(/\/\/ 📂/g, '// ');
content = content.replace(/\/\/ ✅/g, '// ');
content = content.replace(/\/\/ ✏️/g, '// ');
content = content.replace(/\/\/ 🔐/g, '// ');

fs.writeFileSync(filePath, content, 'utf-8');
console.log('Fixed index.js!');
