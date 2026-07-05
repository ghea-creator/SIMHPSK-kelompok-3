# ⚙️ Command Prompt vs PowerShell - Pilih Mana?

## 🎯 Perbedaan Singkat

| Aspek | Command Prompt (cmd) | PowerShell |
|-------|-----|-----|
| **Syntax** | Sederhana | Lebih modern/complex |
| **Operator Chain** | `cd ... && npm run dev` | `cd ...; npm run dev` |
| **Untuk Project Ini** | ✅ Lebih mudah | ✅ Juga bisa |
| **Rekomendasi** | ⭐ RECOMMENDED | Juga OK |

---

## 🚀 SOLUSI CEPAT

Anda sudah di folder yang benar, cukup ketik:

```bash
npm run dev
```

**SELESAI!** Tidak perlu `cd` lagi.

---

## 📋 Cara untuk Setiap Terminal

### Command Prompt (Recommended)

```bash
cd c:\laragon\www\backend-absensi && npm run dev
```

Output:
```
[0] 🔧 index.js file is loading...
...
[0] Server jalan di http://localhost:5000 ✅

[1] ➜  Local:   http://localhost:5173/
```

### PowerShell

Kalau Anda menggunakan PowerShell, gunakan **semicolon** (`;`) bukan `&&`:

```powershell
cd c:\laragon\www\backend-absensi; npm run dev
```

Atau lebih simple, jika Anda sudah di folder tersebut:

```powershell
npm run dev
```

---

## ❌ Error yang Mungkin Muncul

### Error di PowerShell:
```
The token '&&' is not a valid statement separator in this version.
```

**Penyebab:** PowerShell tidak recognize operator `&&`

**Solusi:**
- Gunakan `;` sebagai ganti `&&`
- Atau lebih mudah: gunakan Command Prompt
- Atau: jika sudah di folder, langsung `npm run dev`

---

## 🎯 REKOMENDASI

### Jika Anda pengguna baru → Gunakan **Command Prompt**
- Syntax lebih simpel
- Tidak perlu worry tentang operator yang berbeda

### Jika Anda terbiasa PowerShell → Gunakan **PowerShell**
- Gunakan `;` untuk chain commands
- Semuanya akan berfungsi normal

---

## 🎬 Complete Command untuk Setiap Terminal

### Command Prompt:
```bash
cd c:\laragon\www\backend-absensi && npm run dev
```

### PowerShell:
```powershell
cd c:\laragon\www\backend-absensi; npm run dev
```

### Jika Sudah di Folder (Both):
```bash
npm run dev
```

---

## ✅ Best Practice

Jika ingin simple dan tidak perlu hafal syntax:

**Step 1: Manual navigate**
```bash
cd c:\laragon\www\backend-absensi
```

**Step 2: Run command**
```bash
npm run dev
```

Ini bekerja di **Command Prompt dan PowerShell** tanpa masalah! ✅

---

💡 **Pro Tip:** Gunakan Command Prompt untuk development, itu paling straightforward!

Selamat menggunakan! 🚀
