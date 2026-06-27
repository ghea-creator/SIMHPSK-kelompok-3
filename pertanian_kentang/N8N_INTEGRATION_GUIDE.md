# 🚀 N8N Integration Guide untuk TaniBot Chatbot

## 📋 Overview

TaniBot sekarang menggunakan **n8n** sebagai automation platform untuk memproses chat messages. n8n bertindak sebagai **middleware** yang:
- Menerima pesan chat dari Laravel API
- Memproses pesan dengan sistem prompt yang sudah dikonfigurasi
- Memanggil Groq API untuk mendapatkan respons AI
- Mengembalikan respons ke frontend

```mermaid
graph LR
    A[Flutter/Laravel Frontend] -->|POST /api/chat| B[Laravel ChatbotController]
    B -->|POST webhook| C[n8n Workflow]
    C -->|POST| D[Groq API]
    D -->|Response| C
    C -->|JSON Reply| B
    B -->|JSON Reply| A
```

---

## ✅ Prerequisites

Sebelum setup n8n, pastikan sudah memiliki:

1. **n8n installed** (self-hosted atau n8n cloud)
   - Self-hosted: `npm install -g n8n`
   - Cloud: https://app.n8n.cloud

2. **Groq API Key**
   - Daftar di https://groq.com/
   - Ambil API key dari dashboard Groq

3. **Laravel Project** (yang sudah di-update)
   - ChatbotController sudah menggunakan n8n webhook
   - .env sudah dikonfigurasi dengan N8N_WEBHOOK_URL

---

## 🔧 Setup N8N

### Step 1: Install n8n (Self-Hosted)

#### A. Menggunakan npm
```bash
npm install -g n8n

# Jalankan n8n
n8n
```

#### B. Menggunakan Docker
```bash
docker run -it --rm --name n8n -p 5678:5678 -v ~/.n8n:/home/node/.n8n n8nio/n8n
```

#### C. Menggunakan Docker Compose (Recommended)
```yaml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=password
      - N8N_HOST=0.0.0.0
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - DATABASE_URL=postgresql://user:password@postgres:5432/n8n
      - NODE_ENV=production
    volumes:
      - n8n_storage:/home/node/.n8n
    depends_on:
      - postgres

  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: n8n
    volumes:
      - postgres_storage:/var/lib/postgresql/data

volumes:
  n8n_storage:
  postgres_storage:
```

### Step 2: Akses n8n Dashboard

Buka browser dan akses:
```
http://localhost:5678
```

Login dengan username dan password yang sudah dikonfigurasi.

### Step 3: Setup Groq API Credential

1. **Buka n8n Dashboard**
2. **Klik Credentials** (icon kunci di toolbar kiri)
3. **Klik "+ New"** atau **"Create New Credential"**
4. **Cari dan pilih "Groq API"**
   - Jika belum ada, cari "HTTP Request" dan gunakan manual config
5. **Masukkan Groq API Key:**
   ```
   API Key: [YOUR_GROQ_API_KEY]
   ```
6. **Klik Save**

---

## 📦 Import Workflow TaniBot

### Method 1: Import dari File JSON (Recommended)

1. **Di n8n Dashboard, klik menu** (hamburger icon) di atas sebelah kiri
2. **Pilih "Workflows"** atau **"Import"**
3. **Klik "+ Import Workflow"** atau **"Import from file"**
4. **Pilih file:** `n8n/TaniBot_Chat_Workflow.json` dari project Laravel
5. **Klik Import**
6. **Workflow akan ter-import dengan nama "TaniBot Chat Processing Workflow"**

### Method 2: Manual Setup Workflow

Jika import gagal, buat workflow manual dengan langkah-langkah di bawah:

#### Node 1: Webhook (Trigger)
1. **Add Node** → **Core Nodes** → **Webhook**
2. **Configure:**
   - **Method:** POST
   - **Path:** `tanibot-chat`
   - **Response Mode:** "When Last Node Completes"
   - **Authentication:** None (akan diberi auth via Laravel)
   - **Klik Save**
3. **Catat URL webhook yang muncul:**
   ```
   http://[YOUR_N8N_HOST]:5678/webhook/[workflow-id]/tanibot-chat
   ```

#### Node 2: Build Groq Request
1. **Add Node** → **Core Nodes** → **Function**
2. **Name:** "Build Groq Request"
3. **Code:**
```javascript
return [
  {
    body: {
      model: "llama-3.1-8b-instant",
      messages: [
        {
          role: "system",
          content: "Kamu adalah TaniBot, asisten AI resmi aplikasi SIMHPSK (Sistem Informasi Manajemen Hasil Panen dan Stok Kentang).\n\nAplikasi SIMHPSK memiliki fitur-fitur berikut:\n- 🌱 Musim Tanam: mencatat dan mengelola musim tanam kentang\n- 🚜 Pencatatan Panen: mencatat hasil panen kentang per musim\n- 📦 Stok Gudang: memantau stok masuk dan keluar gudang\n- 💰 Penjualan: mencatat transaksi penjualan kentang\n- 📊 Biaya Produksi: mencatat pengeluaran biaya pertanian\n- 📈 Laporan: melihat untung/rugi dan target vs realisasi panen\n- ⚙️ Pengaturan: mengatur profil dan notifikasi\n\nTugasmu:\n1. Utamakan menjawab pertanyaan seputar fitur aplikasi SIMHPSK\n2. Jika user bertanya cara mencatat panen, arahkan ke menu Pencatatan Panen\n3. Jika user bertanya soal stok, arahkan ke menu Stok Gudang\n4. Jika user bertanya soal laporan, arahkan ke menu Laporan\n5. Tetap bantu pertanyaan seputar pertanian kentang secara umum\n6. Selalu promosikan fitur aplikasi yang relevan di akhir jawaban\n7. Gunakan emoji yang relevan agar lebih menarik\n8. Jawab dalam bahasa Indonesia yang ramah dan mudah dipahami petani"
        },
        {
          role: "user",
          content: $json.message
        }
      ],
      max_tokens: 1000
    }
  }
];
```
4. **Klik Save**

#### Node 3: Call Groq API
1. **Add Node** → **Core Nodes** → **HTTP Request**
2. **Configure:**
   - **URL:** `https://api.groq.com/openai/v1/chat/completions`
   - **Method:** POST
   - **Headers:**
     ```
     Authorization: Bearer {{ env.GROQ_API_KEY }}
     Content-Type: application/json
     ```
   - **Body Params (raw JSON):**
     ```json
     {{ $json.body }}
     ```
   - **Authentication:** None
3. **Klik Save**

#### Node 4: Extract Response
1. **Add Node** → **Core Nodes** → **Function**
2. **Name:** "Extract Response"
3. **Code:**
```javascript
return [
  {
    reply: $json.choices[0].message.content
  }
];
```
4. **Klik Save**

#### Node 5: Return Response (Respond to Webhook)
1. **Add Node** → **Core Nodes** → **Respond to Webhook**
2. **Configure:**
   - **Response Code:** 200
   - **Response Data:** `{{ $json }}`
3. **Klik Save**

#### Connect Nodes
1. Drag dari **Webhook** ke **Build Groq Request**
2. Drag dari **Build Groq Request** ke **Call Groq API**
3. Drag dari **Call Groq API** ke **Extract Response**
4. Drag dari **Extract Response** ke **Return Response**

---

## 🔑 Configure Environment Variables

### Di .env file Laravel

```bash
# N8N Configuration
N8N_WEBHOOK_URL=http://localhost:5678/webhook/[workflow-id]/tanibot-chat

# Groq API Key
GROQ_API_KEY=your_groq_api_key_here
```

**Cara mendapatkan N8N_WEBHOOK_URL:**
1. Buka workflow TaniBot di n8n
2. Klik pada **Webhook node** (node pertama)
3. Copy URL yang muncul di bagian "Webhook URLs"
4. Paste ke .env sebagai `N8N_WEBHOOK_URL`

---

## 🧪 Testing Workflow

### Test di n8n
1. **Buka workflow TaniBot**
2. **Klik tombol "Test" (atau Ctrl+Enter)**
3. **Pada Webhook node, klik "Test Webhook"**
4. **Input test data:**
```json
{
  "message": "Bagaimana cara mencatat panen?"
}
```
5. **Klik Send Test Data**
6. **Tunggu response dari Groq API**

### Test dari Laravel

```bash
# Via curl
curl -X POST http://localhost:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"Halo, apa itu TaniBot?"}'

# Via Laravel Tinker
php artisan tinker
> Http::post('http://localhost:8000/api/chat', ['message' => 'Halo'])
```

---

## 📊 Monitoring & Logging

### Lihat Execution Logs

1. **Di n8n Dashboard, klik "Executions"** (tab di atas workflow)
2. **Setiap execution akan tercatat dengan status:**
   - ✅ **Success** (hijau) - workflow berhasil
   - ❌ **Error** (merah) - ada kesalahan
3. **Klik execution untuk melihat detail:**
   - Input data
   - Output di setiap node
   - Error messages (jika ada)

### Enable Logging di Laravel

Tambahkan logging di ChatbotController untuk debugging:

```php
\Log::info('N8N Chat Request', [
    'message' => $userMessage,
    'url' => $n8nWebhookUrl,
    'timestamp' => now()
]);
```

---

## ⚠️ Common Issues & Solutions

### 1. Webhook URL Connection Refused
**Problem:** Laravel tidak bisa terhubung ke n8n
**Solution:**
- Pastikan n8n sudah running
- Periksa firewall rules
- Gunakan IP address yang benar (bukan localhost jika berbeda machine)
- Test connectivity: `curl http://n8n-url:5678/health`

### 2. Groq API Error (401 Unauthorized)
**Problem:** API key salah atau invalid
**Solution:**
- Verify API key di https://groq.com/
- Pastikan API key sudah di-set di credential n8n
- Cek environment variable di n8n

### 3. Timeout Error
**Problem:** n8n atau Groq API lambat
**Solution:**
- Increase timeout di ChatbotController: `Http::timeout(60)`
- Cek status Groq API: https://status.groq.com/
- Reduce `max_tokens` dari 1000 ke 500

### 4. CORS Error (jika frontend berbeda origin)
**Solution:**
Tambahkan CORS headers di n8n atau gunakan proxy di Laravel

---

## 🔄 Update & Deployment

### Push Workflow ke Production

**Method 1: Export & Import**
1. Di development, klik menu → Export Workflow
2. Save file JSON
3. Di production, Import workflow tersebut

**Method 2: Version Control**
```bash
# Simpan workflow JSON di git
git add n8n/TaniBot_Chat_Workflow.json
git commit -m "Update TaniBot n8n workflow"
git push
```

### Update Workflow

Setelah update:
1. **Stop execution** (jika sedang berjalan)
2. **Edit workflow** sesuai kebutuhan
3. **Test** dengan Test button
4. **Klik Save**
5. **Activate workflow** (toggle di atas)

---

## 📈 Performance Tips

1. **Caching responses** (optional):
   - Gunakan n8n Function node untuk cache responses
   - Reduce API calls ke Groq

2. **Batch processing**:
   - Jika banyak requests, gunakan n8n Queue trigger

3. **Error handling**:
   - Tambahkan error handling node di workflow
   - Graceful degradation jika Groq API down

---

## 🔐 Security Best Practices

1. **Never expose API keys:**
   - Gunakan n8n Credentials management
   - Jangan hardcode di workflow

2. **Enable authentication:**
   - Jika n8n public, set N8N_BASIC_AUTH_ACTIVE=true
   - Gunakan strong passwords

3. **Validate webhook requests:**
   - Verify Laravel request signature
   - Implement rate limiting

4. **Use HTTPS in production:**
   - Update N8N_PROTOCOL=https
   - Update N8N_WEBHOOK_URL dengan https

---

## 📞 Support & Resources

- **n8n Documentation:** https://docs.n8n.io/
- **n8n Community:** https://community.n8n.io/
- **Groq API Docs:** https://groq.com/documentation/
- **Laravel HTTP Client:** https://laravel.com/docs/http-client

---

## ✨ Next Steps

Setelah setup n8n berhasil:

1. ✅ Test workflow dengan berbagai pertanyaan
2. ✅ Monitor execution logs secara berkala
3. ✅ Optimize prompt di Function node jika diperlukan
4. ✅ Backup workflow ke git repository
5. ✅ Implement additional features (logging, analytics, etc.)

---

**Last Updated:** Mei 2026
**Status:** ✅ n8n Integration Complete
