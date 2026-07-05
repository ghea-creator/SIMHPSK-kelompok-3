<!DOCTYPE html>
<html lang="id" class="scroll-smooth">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SIMHPSK - Pencatatan Pertanian</title>
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Nunito:wght@700;900&display=swap" rel="stylesheet">
    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    fontFamily: {
                        sans: ['Plus Jakarta Sans', 'sans-serif'],
                        heading: ['Nunito', 'sans-serif'],
                    },
                    colors: {
                        primary: '#2d6a4f',
                        'primary-dark': '#1b4332',
                        secondary: '#40916c',
                        surface: '#f2ede3', // Matches Flutter 0xFFF2EDE3
                        darkbg: '#1E3A2A' // Matches Flutter How It Works
                    }
                }
            }
        }
    </script>
    <style>
        body {
            background-color: #f3f4ec;
            overflow-x: hidden;
        }
        
        /* Background Blurs */
        .blur-circle {
            position: absolute;
            border-radius: 50%;
            filter: blur(100px);
            z-index: -1;
            opacity: 0.6;
        }
        
        .blur-green {
            background-color: #a3b18a;
            width: 800px;
            height: 800px;
            top: -100px;
            left: -200px;
        }

        .blur-yellow {
            background-color: #e9c46a;
            width: 700px;
            height: 700px;
            bottom: -150px;
            right: -150px;
        }
        
        .underline-doodle {
            position: relative;
            display: inline-block;
        }
        .underline-doodle::after {
            content: '';
            position: absolute;
            left: 0;
            bottom: -2px;
            width: 100%;
            height: 8px;
            background: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 10" preserveAspectRatio="none"><path d="M0 5 Q 50 10 100 5" stroke="%2340916c" stroke-width="3" fill="none"/></svg>') no-repeat center;
            background-size: 100% 100%;
        }

        /* Float animation */
        @keyframes float {
            0% { transform: translateY(0px); }
            50% { transform: translateY(-20px); }
            100% { transform: translateY(0px); }
        }
        .animate-float {
            animation: float 6s ease-in-out infinite;
        }

        /* Heartbeat animation for button */
        @keyframes heartbeat {
            0%, 100% { transform: scale(1); }
            10%, 30% { transform: scale(1.05); }
            20% { transform: scale(1.02); }
        }
        .animate-heartbeat {
            animation: heartbeat 2s infinite;
        }

        /* Blob animation */
        @keyframes blob {
            0% { transform: translate(0px, 0px) scale(1); }
            33% { transform: translate(30px, -50px) scale(1.1); }
            66% { transform: translate(-20px, 20px) scale(0.9); }
            100% { transform: translate(0px, 0px) scale(1); }
        }
        .animate-blob {
            animation: blob 12s ease-in-out infinite alternate;
        }
        .animation-delay-2000 {
            animation-delay: 2s;
        }
        .animation-delay-4000 {
            animation-delay: 4s;
        }
    </style>
</head>
<body class="font-sans antialiased text-gray-800 flex flex-col relative min-h-screen">

    <!-- Background Decoration Hero -->
    <div class="blur-circle blur-green top-0 left-[-200px] animate-blob"></div>
    <div class="blur-circle blur-yellow top-40 right-[-150px] animate-blob animation-delay-2000"></div>

    <!-- Navbar -->
    <nav class="sticky top-0 backdrop-blur-md bg-white/70 border-b border-gray-200/50 flex justify-between items-center px-8 py-4 mx-auto w-full z-50">
        <div class="max-w-7xl mx-auto w-full flex justify-between items-center">
            <!-- Logo -->
            <div class="flex items-center gap-3">
                <div class="w-10 h-10 bg-primary rounded-xl flex items-center justify-center text-white">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4" />
                    </svg>
                </div>
                <div>
                    <h1 class="text-xl font-bold leading-none text-primary-dark tracking-tight">SIMHPSK</h1>
                    <p class="text-[10px] text-gray-500 font-semibold tracking-wider uppercase mt-1">Pencatatan Pertanian</p>
                </div>
            </div>

            <!-- Links -->
            <div class="hidden md:flex items-center gap-8 text-sm font-semibold text-gray-600">
                <a href="#fitur" class="hover:text-primary transition">Fitur</a>
                <a href="#statistik" class="hover:text-primary transition">Statistik</a>
                <a href="#cara-kerja" class="hover:text-primary transition">Cara Kerja</a>
                <a href="#ulasan" class="hover:text-primary transition">Ulasan</a>
            </div>

            <!-- Actions -->
            <div class="flex items-center gap-4">
                <button onclick="handleAppRouting()" class="text-sm font-semibold text-white bg-primary hover:bg-primary-dark transition px-6 py-2.5 rounded-full flex items-center gap-2 shadow-lg shadow-primary/30 animate-heartbeat">
                    Download Aplikasi
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z" clip-rule="evenodd" />
                    </svg>
                </button>
            </div>
        </div>
    </nav>

    <!-- 1. HERO SECTION -->
    <section class="flex flex-col items-center justify-center text-center px-4 z-10 pt-20 pb-24">
        <!-- Badge -->
        <div class="inline-flex items-center gap-2 bg-green-100/80 backdrop-blur-sm border border-green-200 text-primary-dark px-4 py-1.5 rounded-full text-xs font-bold uppercase tracking-wide mb-8 shadow-sm">
            <div class="w-2 h-2 bg-secondary rounded-full animate-pulse"></div>
            Platform Manajemen Pertanian Digital #1
        </div>

        <!-- Headline -->
        <h2 class="text-5xl md:text-6xl font-heading font-extrabold text-primary-dark max-w-4xl leading-[1.15] tracking-tight">
            Kelola Panen dan Stok <span class="text-primary">Kentang</span> dengan Mudah<br/>
            Lebih <span class="text-secondary">Cerdas</span>
        </h2>

        <!-- Subheadline -->
        <p class="mt-8 text-gray-600 font-medium max-w-2xl text-lg leading-relaxed">
            Sistem Informasi Manajemen Panen dan Stok Kentang yang membantu Anda mengelola usaha pertanian dengan lebih efisien dan menguntungkan.
        </p>

        <!-- CTA Buttons -->
        <div class="flex flex-col sm:flex-row items-center gap-4 mt-12">
            <button onclick="handleAppRouting()" class="text-base font-semibold text-white bg-primary hover:bg-primary-dark transition-all px-8 py-3.5 rounded-full flex items-center gap-3 shadow-xl shadow-primary/30 w-full sm:w-auto justify-center hover:-translate-y-1 animate-heartbeat">
                Download Aplikasi Android
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z" clip-rule="evenodd" />
                </svg>
            </button>
        </div>

        <!-- Features Checklist -->
        <div class="flex flex-wrap items-center justify-center gap-6 mt-8 text-sm font-medium text-gray-600">
            <div class="flex items-center gap-2"><span class="text-green-600 text-lg">✅</span> Mudah digunakan</div>
            <div class="flex items-center gap-2"><span class="text-blue-500 text-lg">🆓</span> Gratis selamanya</div>
            <div class="flex items-center gap-2"><span class="text-yellow-500 text-lg">🔒</span> Data aman & terenkripsi</div>
        </div>

        <!-- Mockup Dashboard -->
        <div class="mt-20 w-full max-w-4xl bg-white rounded-2xl shadow-2xl border border-gray-100 p-4 md:p-8 animate-float relative z-10">
            <!-- Window controls -->
            <div class="flex items-center gap-2 mb-6">
                <div class="w-3 h-3 rounded-full bg-red-500"></div>
                <div class="w-3 h-3 rounded-full bg-yellow-500"></div>
                <div class="w-3 h-3 rounded-full bg-green-500"></div>
            </div>
            
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
                <div class="bg-yellow-50 p-4 rounded-xl border border-yellow-100">
                    <p class="text-yellow-800 text-xs font-bold mb-1">Stok Gudang</p>
                    <p class="text-yellow-600 text-xl font-black">4.500 kg</p>
                </div>
                <div class="bg-green-50 p-4 rounded-xl border border-green-100">
                    <p class="text-green-800 text-xs font-bold mb-1">Total Panen</p>
                    <p class="text-green-600 text-xl font-black">12.400 kg</p>
                </div>
                <div class="bg-blue-50 p-4 rounded-xl border border-blue-100">
                    <p class="text-blue-800 text-xs font-bold mb-1">Pendapatan</p>
                    <p class="text-blue-600 text-xl font-black">Rp 74,4 jt</p>
                </div>
                <div class="bg-teal-50 p-4 rounded-xl border border-teal-100">
                    <p class="text-teal-800 text-xs font-bold mb-1">Est. Untung</p>
                    <p class="text-teal-600 text-xl font-black">Rp 28,6 jt</p>
                </div>
            </div>

            <!-- Chart mockup -->
            <div class="h-48 border border-gray-100 rounded-xl bg-gray-50 p-4 flex items-end gap-4 justify-between">
                <div class="w-full bg-green-200 rounded-t-sm" style="height: 60%"></div>
                <div class="w-full bg-blue-200 rounded-t-sm" style="height: 80%"></div>
                <div class="w-full bg-green-200 rounded-t-sm" style="height: 45%"></div>
                <div class="w-full bg-blue-200 rounded-t-sm" style="height: 90%"></div>
                <div class="w-full bg-green-200 rounded-t-sm" style="height: 70%"></div>
                <div class="w-full bg-blue-200 rounded-t-sm" style="height: 100%"></div>
            </div>
        </div>
    </section>

    <!-- 2. STATS SECTION -->
    <section id="statistik" class="w-full bg-primary-dark text-white py-16 px-4 relative overflow-hidden">
        <div class="absolute inset-0 bg-primary opacity-30 pattern-dots"></div>
        <div class="max-w-6xl mx-auto grid grid-cols-2 md:grid-cols-4 gap-8 relative z-10">
            <div class="text-center">
                <p class="text-4xl font-black text-green-400 mb-2">1200<span class="text-2xl text-green-200">+</span></p>
                <p class="text-sm font-semibold uppercase tracking-wider text-green-100 opacity-80">Petani Aktif</p>
            </div>
            <div class="text-center">
                <p class="text-4xl font-black text-green-400 mb-2">98<span class="text-2xl text-green-200">%</span></p>
                <p class="text-sm font-semibold uppercase tracking-wider text-green-100 opacity-80">Kepuasan Pengguna</p>
            </div>
            <div class="text-center">
                <p class="text-4xl font-black text-green-400 mb-2">45<span class="text-2xl text-green-200"> jt</span></p>
                <p class="text-sm font-semibold uppercase tracking-wider text-green-100 opacity-80">Transaksi Tercatat</p>
            </div>
            <div class="text-center">
                <p class="text-4xl font-black text-green-400 mb-2">100<span class="text-2xl text-green-200">%</span></p>
                <p class="text-sm font-semibold uppercase tracking-wider text-green-100 opacity-80">Aman & Terenkripsi</p>
            </div>
        </div>
    </section>

    <!-- 3. FEATURES SECTION -->
    <section id="fitur" class="w-full bg-surface py-24 px-4">
        <div class="max-w-6xl mx-auto">
            <div class="text-center mb-16">
                <div class="inline-block px-4 py-1.5 bg-green-100 border border-green-200 rounded-full text-xs font-bold text-primary-dark uppercase tracking-wide mb-4">
                    ✨ Fitur Unggulan
                </div>
                <h2 class="text-4xl font-heading font-black text-primary-dark">Semua Yang Anda Butuhkan</h2>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                <!-- Feature 1 -->
                <div class="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 hover:shadow-xl hover:-translate-y-1 transition-all">
                    <div class="w-12 h-12 bg-green-50 text-2xl flex items-center justify-center rounded-xl mb-4">🌾</div>
                    <h3 class="text-xl font-bold text-gray-800 mb-2">Pencatatan Panen</h3>
                    <p class="text-gray-500 text-sm leading-relaxed">Catat setiap hasil panen lengkap dengan foto, berat, dan keterangan blok kebun.</p>
                </div>
                <!-- Feature 2 -->
                <div class="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 hover:shadow-xl hover:-translate-y-1 transition-all">
                    <div class="w-12 h-12 bg-yellow-50 text-2xl flex items-center justify-center rounded-xl mb-4">📦</div>
                    <h3 class="text-xl font-bold text-gray-800 mb-2">Manajemen Stok</h3>
                    <p class="text-gray-500 text-sm leading-relaxed">Pantau stok gudang secara real-time dengan notifikasi batas minimum otomatis.</p>
                </div>
                <!-- Feature 3 -->
                <div class="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 hover:shadow-xl hover:-translate-y-1 transition-all">
                    <div class="w-12 h-12 bg-blue-50 text-2xl flex items-center justify-center rounded-xl mb-4">💰</div>
                    <h3 class="text-xl font-bold text-gray-800 mb-2">Laporan Keuangan</h3>
                    <p class="text-gray-500 text-sm leading-relaxed">Hitung pendapatan, biaya produksi, dan estimasi untung-rugi per musim tanam.</p>
                </div>
                <!-- Feature 4 -->
                <div class="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 hover:shadow-xl hover:-translate-y-1 transition-all">
                    <div class="w-12 h-12 bg-purple-50 text-2xl flex items-center justify-center rounded-xl mb-4">🛒</div>
                    <h3 class="text-xl font-bold text-gray-800 mb-2">Manajemen Penjualan</h3>
                    <p class="text-gray-500 text-sm leading-relaxed">Kelola transaksi penjualan dan data pembeli dalam satu platform terpadu.</p>
                </div>
                <!-- Feature 5 -->
                <div class="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 hover:shadow-xl hover:-translate-y-1 transition-all">
                    <div class="w-12 h-12 bg-cyan-50 text-2xl flex items-center justify-center rounded-xl mb-4">📊</div>
                    <h3 class="text-xl font-bold text-gray-800 mb-2">Analitik & Grafik</h3>
                    <p class="text-gray-500 text-sm leading-relaxed">Visualisasi data panen dan penjualan dengan grafik interaktif yang mudah dipahami.</p>
                </div>
                <!-- Feature 6 -->
                <div class="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 hover:shadow-xl hover:-translate-y-1 transition-all">
                    <div class="w-12 h-12 bg-green-100 text-2xl flex items-center justify-center rounded-xl mb-4">🌱</div>
                    <h3 class="text-xl font-bold text-gray-800 mb-2">Musim Tanam</h3>
                    <p class="text-gray-500 text-sm leading-relaxed">Atur dan pantau setiap periode musim tanam dengan riwayat lengkap.</p>
                </div>
            </div>
        </div>
    </section>

    <!-- 4. HOW IT WORKS SECTION -->
    <section id="cara-kerja" class="w-full bg-darkbg py-24 px-4 text-white relative">
        <div class="max-w-4xl mx-auto">
            <div class="text-center mb-16">
                <div class="inline-block px-4 py-1.5 bg-green-500/15 border border-green-500/25 rounded-full text-xs font-bold text-green-400 uppercase tracking-wide mb-4">
                    Cara Kerja
                </div>
                <h2 class="text-4xl font-heading font-black">Hanya 4 Langkah Mudah</h2>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-4 gap-8 relative">


                <div class="relative z-10 text-center">
                    <div class="w-20 h-20 mx-auto bg-green-500/20 border-2 border-green-400 rounded-full flex items-center justify-center text-3xl mb-4">👤</div>
                    <p class="text-green-400 font-black text-xl mb-1">01</p>
                    <h3 class="font-bold text-lg mb-2">Daftar & Masuk</h3>
                    <p class="text-gray-400 text-sm">Buat akun gratis dalam hitungan menit.</p>
                </div>
                <div class="relative z-10 text-center">
                    <div class="w-20 h-20 mx-auto bg-green-500/20 border-2 border-green-400 rounded-full flex items-center justify-center text-3xl mb-4">📅</div>
                    <p class="text-green-400 font-black text-xl mb-1">02</p>
                    <h3 class="font-bold text-lg mb-2">Atur Musim Tanam</h3>
                    <p class="text-gray-400 text-sm">Tentukan periode dan blok kebun Anda.</p>
                </div>
                <div class="relative z-10 text-center">
                    <div class="w-20 h-20 mx-auto bg-green-500/20 border-2 border-green-400 rounded-full flex items-center justify-center text-3xl mb-4">✏️</div>
                    <p class="text-green-400 font-black text-xl mb-1">03</p>
                    <h3 class="font-bold text-lg mb-2">Catat Aktivitas</h3>
                    <p class="text-gray-400 text-sm">Rekam panen, transaksi, dan pengeluaran.</p>
                </div>
                <div class="relative z-10 text-center">
                    <div class="w-20 h-20 mx-auto bg-green-500/20 border-2 border-green-400 rounded-full flex items-center justify-center text-3xl mb-4">📈</div>
                    <p class="text-green-400 font-black text-xl mb-1">04</p>
                    <h3 class="font-bold text-lg mb-2">Analisis & Tumbuh</h3>
                    <p class="text-gray-400 text-sm">Gunakan laporan untuk keputusan cerdas.</p>
                </div>
            </div>
        </div>
    </section>

    <!-- 5. TESTIMONIALS SECTION -->
    <section id="ulasan" class="w-full bg-surface py-24 px-4">
        <div class="max-w-6xl mx-auto">
            <div class="text-center mb-16">
                <div class="inline-block px-4 py-1.5 bg-yellow-100 border border-yellow-200 rounded-full text-xs font-bold text-yellow-800 uppercase tracking-wide mb-4">
                    ⭐ Ulasan Pengguna
                </div>
                <h2 class="text-4xl font-heading font-black text-primary-dark">Kata Mereka</h2>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div class="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
                    <div class="text-yellow-400 text-sm mb-4">★★★★★</div>
                    <p class="text-gray-600 italic text-sm mb-6 leading-relaxed">"Aplikasi ini luar biasa mudah digunakan! Sekarang saya bisa pantau stok dan untung-rugi dengan mudah dari HP."</p>
                    <div class="flex items-center gap-3">
                        <div class="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center text-xl">👨‍🌾</div>
                        <div>
                            <p class="font-bold text-gray-800 text-sm">Pak Budi Santoso</p>
                            <p class="text-xs text-gray-500">Pangalengan, Jawa Barat</p>
                        </div>
                    </div>
                </div>
                
                <div class="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
                    <div class="text-yellow-400 text-sm mb-4">★★★★★</div>
                    <p class="text-gray-600 italic text-sm mb-6 leading-relaxed">"Sangat membantu untuk mencatat hasil panen. Tulisannya besar dan jelas, cocok untuk saya yang sudah tua."</p>
                    <div class="flex items-center gap-3">
                        <div class="w-10 h-10 bg-pink-100 rounded-full flex items-center justify-center text-xl">👩‍🌾</div>
                        <div>
                            <p class="font-bold text-gray-800 text-sm">Bu Sari Dewi</p>
                            <p class="text-xs text-gray-500">Dieng, Jawa Tengah</p>
                        </div>
                    </div>
                </div>

                <div class="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
                    <div class="text-yellow-400 text-sm mb-4">★★★★★</div>
                    <p class="text-gray-600 italic text-sm mb-6 leading-relaxed">"Laporan keuangannya sangat detail. Saya jadi tahu persis berapa untung setiap musim panen."</p>
                    <div class="flex items-center gap-3">
                        <div class="w-10 h-10 bg-green-100 rounded-full flex items-center justify-center text-xl">🧑‍🌾</div>
                        <div>
                            <p class="font-bold text-gray-800 text-sm">Pak Bambang Susilo</p>
                            <p class="text-xs text-gray-500">Magelang</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- 6. CTA SECTION -->
    <section class="w-full bg-white py-24 px-4">
        <div class="max-w-4xl mx-auto bg-gradient-to-br from-primary to-green-800 rounded-3xl p-10 md:p-16 text-center text-white shadow-2xl relative overflow-hidden">
            <!-- Decorative circle -->
            <div class="absolute top-[-50px] right-[-50px] w-64 h-64 bg-white/10 rounded-full blur-2xl"></div>
            <div class="absolute bottom-[-50px] left-[-50px] w-64 h-64 bg-green-400/20 rounded-full blur-2xl"></div>
            
            <h2 class="text-4xl md:text-5xl font-heading font-black mb-6 relative z-10">Siap Mengelola Panen Anda?</h2>
            <p class="text-green-100 mb-10 max-w-2xl mx-auto relative z-10">Unduh aplikasinya sekarang dan bergabung dengan ribuan petani lain yang sudah mengoptimalkan hasil panen mereka.</p>
            
            <button onclick="handleAppRouting()" class="relative z-10 text-primary-dark font-bold bg-white hover:bg-gray-100 transition px-10 py-4 rounded-full text-lg flex items-center gap-2 mx-auto shadow-xl hover:-translate-y-1 animate-heartbeat">
                Download Aplikasi Android
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z" clip-rule="evenodd" />
                </svg>
            </button>
            
            <div class="flex flex-wrap items-center justify-center gap-6 mt-8 text-sm font-medium text-green-200 relative z-10">
                <div class="flex items-center gap-2"><span>✓</span> Tanpa kartu kredit</div>
                <div class="flex items-center gap-2"><span>✓</span> Setup 5 menit</div>
                <div class="flex items-center gap-2"><span>✓</span> Support 7 hari</div>
            </div>
        </div>
    </section>

    <!-- FOOTER -->
    <footer class="bg-gray-50 border-t border-gray-200 py-12 px-4">
        <div class="max-w-6xl mx-auto flex flex-col md:flex-row justify-between items-center gap-6">
            <div class="flex items-center gap-3">
                <div class="w-8 h-8 bg-primary rounded-lg flex items-center justify-center text-white">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4" /></svg>
                </div>
                <span class="font-bold text-gray-800 tracking-tight">SIMHPSK</span>
            </div>
            
            <div class="flex items-center gap-6 text-sm text-gray-500 font-medium">
                <a href="#fitur" class="hover:text-primary">Fitur</a>
                <a href="#cara-kerja" class="hover:text-primary">Cara Kerja</a>
                <a href="#ulasan" class="hover:text-primary">Ulasan</a>
            </div>
            
            <div class="text-sm text-gray-400">
                © 2026 SIMHPSK. All rights reserved.
            </div>
        </div>
    </footer>

    <!-- Script for Deep Linking & Animations -->
    <script>
        // Deep Linking
        function handleAppRouting() {
            var appScheme = "simhpsk://open"; 
            var downloadUrl = "/download/simhpsk.apk"; 

            window.location.href = appScheme;

            setTimeout(function() {
                window.location.href = downloadUrl;
            }, 2000);
        }

        // Scroll Animations (FadeSlideOnScroll equivalent)
        document.addEventListener('DOMContentLoaded', function() {
            const observerOptions = {
                root: null,
                rootMargin: '0px',
                threshold: 0.15
            };

            const observer = new IntersectionObserver((entries, observer) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        entry.target.classList.add('opacity-100', 'translate-y-0');
                        entry.target.classList.remove('opacity-0', 'translate-y-8');
                        observer.unobserve(entry.target);
                    }
                });
            }, observerOptions);

            // Select all sections and feature cards to animate
            const animatedElements = document.querySelectorAll('section > div, .grid > div');
            animatedElements.forEach(el => {
                // Add initial state classes
                el.classList.add('transition-all', 'duration-1000', 'opacity-0', 'translate-y-8');
                observer.observe(el);
            });
        });
    </script>
</body>
</html>
