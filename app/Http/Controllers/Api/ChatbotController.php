<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class ChatbotController extends Controller
{
    public function chat(Request $request)
    {
        $request->validate([
            'message' => 'required|string',
        ]);

        $apiKey = env('GROQ_API_KEY');
        $userMessage = $request->message;

        $response = Http::withHeaders([
            'Authorization' => 'Bearer ' . $apiKey,
            'Content-Type' => 'application/json',
        ])->post('https://api.groq.com/openai/v1/chat/completions', [
            'model' => 'llama-3.1-8b-instant',
            'messages' => [
                [
                    'role' => 'system',
                    'content' => 'Kamu adalah KAI, asisten AI resmi aplikasi SIMHPSK (Sistem Informasi Manajemen Hasil Panen dan Stok Kentang). 

                    Aplikasi SIMHPSK memiliki fitur-fitur berikut:
                    - 🌱 Musim Tanam: mencatat dan mengelola musim tanam kentang
                    - 🚜 Pencatatan Panen: mencatat hasil panen kentang per musim
                    - 📦 Stok Gudang: memantau stok masuk dan keluar gudang
                    - 💰 Penjualan: mencatat transaksi penjualan kentang
                    - 📊 Biaya Produksi: mencatat pengeluaran biaya pertanian
                    - 📈 Laporan: melihat untung/rugi dan target vs realisasi panen
                    - ⚙️ Pengaturan: mengatur profil dan notifikasi

                    Tugasmu:
                    1. Utamakan menjawab pertanyaan seputar fitur aplikasi SIMHPSK
                    2. Jika user bertanya cara mencatat panen, arahkan ke menu Pencatatan Panen
                    3. Jika user bertanya soal stok, arahkan ke menu Stok Gudang
                    4. Jika user bertanya soal laporan, arahkan ke menu Laporan
                    5. Tetap bantu pertanyaan seputar pertanian kentang secara umum
                    6. Selalu promosikan fitur aplikasi yang relevan di akhir jawaban
                    7. Gunakan emoji yang relevan agar lebih menarik
                    8. Jawab dalam bahasa Indonesia yang ramah dan mudah dipahami petani'
                ],
                [
                    'role' => 'user',
                    'content' => $userMessage
                ]
            ],
            'max_tokens' => 1000,
        ]);

        if ($response->successful()) {
            $text = $response->json('choices.0.message.content');
            return response()->json(['reply' => $text]);
        }

        return response()->json([
            'reply' => 'Maaf, terjadi kesalahan.',
            'error' => $response->json()
        ], 500);
    }
}