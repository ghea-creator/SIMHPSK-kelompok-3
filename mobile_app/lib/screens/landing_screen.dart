import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../login_screen.dart';
import 'register_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ApiService _apiService = ApiService();
  Map<String, String> _landingContent = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLandingContent();
  }

  Future<void> _loadLandingContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getLandingContent();
      if (mounted) {
        setState(() {
          _landingContent = data?.map((key, value) => MapEntry(key, value?.toString() ?? '')) ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _landingValue(String key, String fallback) {
    final value = _landingContent[key];
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF108548),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.agriculture_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'SIMHPSK',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text('Login', style: TextStyle(color: Color(0xFF108548), fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF108548),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                );
              },
              child: const Text('Mulai Gratis'),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF108548)))
          : SingleChildScrollView(
              child: Column(
                children: [
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      color: Colors.red.shade50,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  _buildHeroSection(context),
                  _buildFeaturesSection(),
                  _buildCtaSection(context),
                  _buildFooter(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF0FDF4),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 6, child: _buildHeroLeftContent(context)),
                    const SizedBox(width: 40),
                    Expanded(flex: 5, child: _buildHeroRightContent()),
                  ],
                );
              }
              return Column(
                children: [
                  _buildHeroLeftContent(context),
                  const SizedBox(height: 60),
                  _buildHeroRightContent(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeroLeftContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Color(0xFF108548), size: 18),
              SizedBox(width: 8),
              Text(
                'Solusi Manajemen Pertanian Modern',
                style: TextStyle(
                  color: Color(0xFF108548),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
              height: 1.2,
            ),
            children: [
              TextSpan(text: _landingValue('hero_title', 'Kelola Panen & Stok Kentang dengan ')),
              TextSpan(
                text: _landingValue('hero_title_emphasis', 'Lebih Efisien'),
                style: const TextStyle(color: Color(0xFF108548)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _landingValue(
            'hero_description',
            'SIMHPSK membantu petani kentang mengelola produksi, stok gudang, keuangan, dan karyawan dalam satu platform terintegrasi.',
          ),
          style: const TextStyle(
            fontSize: 18,
            color: Color(0xFF4B5563),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF108548),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _landingValue('hero_cta_1', 'Mulai Gratis'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF108548),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                side: const BorderSide(color: Color(0xFF108548), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: Text(
                _landingValue('hero_cta_2', 'Login'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatText('100%', 'Otomatis'),
            _buildStatText('24/7', 'Monitoring'),
            _buildStatText('Real-time', 'Data Update'),
            _buildStatText('Cloud', 'Based System'),
          ],
        ),
      ],
    );
  }

  Widget _buildStatText(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildHeroRightContent() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Decorative background element
        Container(
          width: 400,
          height: 400,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Color(0x26108548), Colors.transparent],
              stops: [0.0, 0.7],
            ),
          ),
        ),
        // Stat Cards Wrapper
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 50,
                offset: const Offset(0, 25),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatCard(
                icon: Icons.inventory_2_outlined,
                label: 'Total Gudang',
                value: '2,450 kg',
                bgColor: const Color(0xFFF0FDF4),
                borderColor: const Color(0xFFDCFCE7),
                iconBgColor: const Color(0xFF108548),
                valueColor: const Color(0xFF111827),
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                icon: Icons.bar_chart_outlined,
                label: 'Total Panen',
                value: '12,890 kg',
                bgColor: const Color(0xFFEFF6FF),
                borderColor: const Color(0xFFDBEAFE),
                iconBgColor: const Color(0xFF2563EB),
                valueColor: const Color(0xFF1D4ED8),
                labelColor: const Color(0xFF2563EB),
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                icon: Icons.trending_up_outlined,
                label: 'Untung Musim Ini',
                value: 'Rp 45,2 Jt',
                bgColor: const Color(0xFFFAF5FF),
                borderColor: const Color(0xFFF3E8FF),
                iconBgColor: const Color(0xFF9333EA),
                valueColor: const Color(0xFF7E22CE),
                labelColor: const Color(0xFF9333EA),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color bgColor,
    required Color borderColor,
    required Color iconBgColor,
    required Color valueColor,
    Color labelColor = const Color(0xFF4B5563),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 80.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const Text(
                'Fitur Lengkap untuk Manajemen Pertanian',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Semua yang Anda butuhkan untuk mengelola bisnis kentang Anda',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 1;
                  if (constraints.maxWidth > 900) {
                    crossAxisCount = 3;
                  } else if (constraints.maxWidth > 600) {
                    crossAxisCount = 2;
                  }
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: crossAxisCount == 1 ? 2.5 : (constraints.maxWidth / crossAxisCount) / 250,
                    children: [
                      _buildFeatureCard(
                        icon: Icons.inventory_2,
                        title: _landingValue('feature_1_title', 'Manajemen Stok Real-time'),
                        desc: _landingValue(
                          'feature_1_desc',
                          'Pantau stok gudang Anda secara real-time dengan akurasi tinggi dan laporan otomatis.',
                        ),
                      ),
                      _buildFeatureCard(
                        icon: Icons.bar_chart,
                        title: _landingValue('feature_2_title', 'Analisis Panen & Produksi'),
                        desc: _landingValue(
                          'feature_2_desc',
                          'Catat hasil panen setiap musim dengan grafik dan statistik lengkap.',
                        ),
                      ),
                      _buildFeatureCard(
                        icon: Icons.trending_up,
                        title: _landingValue('feature_3_title', 'Laporan Keuangan Otomatis'),
                        desc: _landingValue(
                          'feature_3_desc',
                          'Hitung untung/rugi secara otomatis dengan visualisasi yang mudah dipahami.',
                        ),
                      ),
                      _buildFeatureCard(
                        icon: Icons.people,
                        title: _landingValue('feature_4_title', 'Manajemen Karyawan'),
                        desc: _landingValue(
                          'feature_4_desc',
                          'Kelola data karyawan dan upah dengan sistem perhitungan otomatis.',
                        ),
                      ),
                      _buildFeatureCard(
                        icon: Icons.file_download,
                        title: _landingValue('feature_5_title', 'Laporan Export PDF/Excel'),
                        desc: _landingValue(
                          'feature_5_desc',
                          'Ekspor semua laporan ke format PDF dan Excel untuk dokumentasi.',
                        ),
                      ),
                      _buildFeatureCard(
                        icon: Icons.phone_android,
                        title: _landingValue('feature_6_title', 'Responsive Design'),
                        desc: _landingValue(
                          'feature_6_desc',
                          'Akses optimal dari desktop, tablet, maupun smartphone Anda kapan saja.',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({required IconData icon, required String title, required String desc}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF108548),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCtaSection(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF108548),
              borderRadius: BorderRadius.circular(32),
            ),
            padding: const EdgeInsets.all(40),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return Row(
                    children: [
                      Expanded(flex: 6, child: _buildCtaLeft()),
                      const SizedBox(width: 40),
                      Expanded(flex: 5, child: _buildCtaRight(context)),
                    ],
                  );
                }
                return Column(
                  children: [
                    _buildCtaLeft(),
                    const SizedBox(height: 40),
                    _buildCtaRight(context),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCtaLeft() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mengapa Memilih SIMHPSK?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),
        _buildBenefitItem('Hemat waktu dengan otomasi pencatatan'),
        _buildBenefitItem('Kurangi kesalahan manual hingga 95%'),
        _buildBenefitItem('Keputusan bisnis berbasis data akurat'),
        _buildBenefitItem('Tingkatkan profit dengan analisis mendalam'),
        _buildBenefitItem('Akses data kapan saja, dimana saja'),
        _buildBenefitItem('Dukungan teknis responsif 24/7'),
      ],
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFFF59E0B), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaRight(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Siap Memulai?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bergabunglah dengan ratusan petani kentang yang telah meningkatkan produktivitas mereka dengan SIMHPSK.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF108548),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Daftar Gratis Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF108548),
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFF108548), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Sudah Punya Akun? Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Column(
        children: [
          Text(
            '© 2026 SIMHPSK Kelompok Tani Kentang.',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Didukung oleh Laravel & Flutter',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
