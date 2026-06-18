import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LandingEditorScreen extends StatefulWidget {
  const LandingEditorScreen({super.key});

  @override
  State<LandingEditorScreen> createState() => _LandingEditorScreenState();
}

class _LandingEditorScreenState extends State<LandingEditorScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = true;
  bool _isSaving = false;

  // Controllers map for dynamically handling the 16 sections
  final Map<String, TextEditingController> _controllers = {};
  
  final List<String> _sections = [
    'hero_title', 'hero_description', 'hero_cta_1', 'hero_cta_2',
    'feature_1_title', 'feature_1_desc', 'feature_2_title', 'feature_2_desc',
    'feature_3_title', 'feature_3_desc', 'feature_4_title', 'feature_4_desc',
    'feature_5_title', 'feature_5_desc', 'feature_6_title', 'feature_6_desc',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    for (var sec in _sections) {
      _controllers[sec] = TextEditingController();
    }
    _loadLandingContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadLandingContent() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getLandingContent();
      if (data != null) {
        data.forEach((section, content) {
          if (_controllers.containsKey(section)) {
            _controllers[section]!.text = content?.toString() ?? '';
          }
        });
      }
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil konten landing page: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final Map<String, String> dataToSend = {};
    _controllers.forEach((section, controller) {
      dataToSend[section] = controller.text.trim();
    });

    final result = await _apiService.updateLandingContent(dataToSend);
    setState(() => _isSaving = false);

    if (result['success'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konten Landing Page berhasil diperbarui!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Gagal menyimpan konten'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Landing Page'),
        backgroundColor: const Color(0xFF135835),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Hero & CTA'),
            Tab(text: 'Fitur Unggulan'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF135835)))
          : Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHeroTab(),
                  _buildFeaturesTab(),
                ],
              ),
            ),
      bottomNavigationBar: _isLoading 
          ? null 
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF135835),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving 
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_rounded),
                  label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Semua Perubahan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
    );
  }

  Widget _buildHeroTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        Widget buildHeroCard() {
          return _buildCardContainer(
            title: 'Bagian Hero (Pembuka)',
            icon: Icons.slideshow_rounded,
            children: [
              TextFormField(
                controller: _controllers['hero_title'],
                decoration: const InputDecoration(labelText: 'Judul Utama (Hero Title)'),
                maxLines: 2,
                validator: (val) => val == null || val.trim().isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controllers['hero_description'],
                decoration: const InputDecoration(labelText: 'Deskripsi Singkat (Hero Description)'),
                maxLines: 4,
                validator: (val) => val == null || val.trim().isEmpty ? 'Wajib diisi' : null,
              ),
            ],
          );
        }

        Widget buildCtaCard() {
          return _buildCardContainer(
            title: 'Tombol CTA (Call to Action)',
            icon: Icons.touch_app_rounded,
            children: [
              TextFormField(
                controller: _controllers['hero_cta_1'],
                decoration: const InputDecoration(labelText: 'Tombol Utama (CTA 1 Label)'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controllers['hero_cta_2'],
                decoration: const InputDecoration(labelText: 'Tombol Pendukung (CTA 2 Label)'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Wajib diisi' : null,
              ),
            ],
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 32.0 : 20.0),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : 700),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: buildHeroCard()),
                        const SizedBox(width: 24),
                        Expanded(child: buildCtaCard()),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildHeroCard(),
                        const SizedBox(height: 20),
                        buildCtaCard(),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturesTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        if (isDesktop) {
          return GridView.count(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(32.0),
            crossAxisCount: constraints.maxWidth > 1200 ? 3 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4,
            children: [
              _buildFeatureEditCard(1),
              _buildFeatureEditCard(2),
              _buildFeatureEditCard(3),
              _buildFeatureEditCard(4),
              _buildFeatureEditCard(5),
              _buildFeatureEditCard(6),
            ],
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildFeatureEditCard(1),
              const SizedBox(height: 16),
              _buildFeatureEditCard(2),
              const SizedBox(height: 16),
              _buildFeatureEditCard(3),
              const SizedBox(height: 16),
              _buildFeatureEditCard(4),
              const SizedBox(height: 16),
              _buildFeatureEditCard(5),
              const SizedBox(height: 16),
              _buildFeatureEditCard(6),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureEditCard(int index) {
    final titleKey = 'feature_${index}_title';
    final descKey = 'feature_${index}_desc';

    return _buildCardContainer(
      title: 'Fitur Utama Ke-$index',
      icon: Icons.star_border_rounded,
      children: [
        TextFormField(
          controller: _controllers[titleKey],
          decoration: const InputDecoration(labelText: 'Judul Fitur'),
          validator: (val) => val == null || val.trim().isEmpty ? 'Wajib diisi' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _controllers[descKey],
          decoration: const InputDecoration(labelText: 'Deskripsi Singkat Fitur'),
          maxLines: 2,
          validator: (val) => val == null || val.trim().isEmpty ? 'Wajib diisi' : null,
        ),
      ],
    );
  }

  Widget _buildCardContainer({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF135835), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}
