# ⚡ N8N Quick Setup Checklist

## 📋 Pre-Setup Checklist

- [ ] Groq API key sudah disiapkan dari https://groq.com/
- [ ] n8n sudah installed (docker/npm/cloud)
- [ ] Laravel ChatbotController sudah di-update
- [ ] .env.example sudah di-update

---

## 🚀 Quick Setup (5 Steps)

### ✅ Step 1: Start n8n
```bash
# Option A: npm
n8n

# Option B: Docker
docker run -it --rm -p 5678:5678 n8nio/n8n

# Option C: Docker Compose
docker-compose up
```
Buka: http://localhost:5678

---

### ✅ Step 2: Add Groq API Credential
1. Klik **Credentials** (icon kunci)
2. Klik **+ New**
3. Cari **"Groq API"** atau **"HTTP Request"**
4. Masukkan **API Key**
5. Klik **Save**

---

### ✅ Step 3: Import Workflow
1. Di Dashboard, klik **Import**
2. Pilih file: `n8n/TaniBot_Chat_Workflow.json`
3. Klik **Import**
4. Workflow akan ter-load

---

### ✅ Step 4: Get Webhook URL
1. Buka workflow "TaniBot Chat Processing Workflow"
2. Klik **Webhook** node (node pertama)
3. Copy URL dari **"Webhook URL"** section
4. Contoh: `http://localhost:5678/webhook/abc123/tanibot-chat`

---

### ✅ Step 5: Update .env
Buat atau update `.env` file di root Laravel:
```bash
N8N_WEBHOOK_URL=http://localhost:5678/webhook/[your-id]/tanibot-chat
GROQ_API_KEY=gsk_your_api_key_here
```

---

## 🧪 Test Workflow

### Test di n8n
1. Klik **Test** button di workflow
2. Pada Webhook node, klik **Test Webhook**
3. Input:
```json
{
  "message": "Berapa harga bibit kentang?"
}
```
4. Klik **Send Test Data**
5. Tunggu response ✅

### Test dari Laravel
```bash
curl -X POST http://localhost:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"Halo TaniBot"}'
```

---

## 🎯 Common N8N Webhook URL Formats

| Type | URL Format |
|------|-----------|
| **Local** | `http://localhost:5678/webhook/[id]/tanibot-chat` |
| **Docker Internal** | `http://n8n:5678/webhook/[id]/tanibot-chat` |
| **Production** | `https://your-domain.com/webhook/[id]/tanibot-chat` |

---

## ⚠️ Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| **Connection Refused** | Pastikan n8n running & firewall open |
| **Groq 401 Error** | Check API key di credential |
| **Timeout** | Increase timeout di ChatbotController |
| **Invalid JSON** | Verify request format di test |

---

## 📁 Files Modified/Created

```
pertanian_kentang/
├── .env                                    [EDIT: Add N8N_WEBHOOK_URL]
├── .env.example                            [✅ UPDATED]
├── N8N_INTEGRATION_GUIDE.md               [✅ CREATED]
├── N8N_QUICK_SETUP.md                     [✅ CREATED - You are here]
├── n8n/
│   └── TaniBot_Chat_Workflow.json         [✅ CREATED]
└── app/Http/Controllers/Api/
    └── ChatbotController.php              [✅ UPDATED]
```

---

## ✨ Done!

Setelah selesai, chatbot Anda akan:
- ✅ Menggunakan n8n sebagai middleware
- ✅ Lebih scalable dan maintainable
- ✅ Mudah dimodifikasi tanpa touch Laravel code
- ✅ Bisa add custom logic di n8n workflow

**Happy Automation! 🎉**
