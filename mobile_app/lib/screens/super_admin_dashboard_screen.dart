import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../login_screen.dart';
import 'user_management_screen.dart';
import 'landing_editor_screen.dart';
import 'custom_menus_screen.dart';
import 'feedback_management_screen.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = true;
  int _totalUsers = 0;
  int _activeUsers = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _apiService.getSuperAdminDashboard();
      if (stats != null) {
        setState(() {
          _totalUsers = stats['totalUsers'] as int? ?? 0;
          _activeUsers = stats['activeUsers'] as int? ?? 0;
        });
      }
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil statistik: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildDesktopHeader(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Panel Super Admin',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF4B5563)),
                onPressed: _loadStats,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        Widget buildBody() {
          return RefreshIndicator(
            onRefresh: _loadStats,
            color: const Color(0xFF135835),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(isDesktop ? 32.0 : 20.0),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF135835), Color(0xFF1A7A4A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selamat Datang, ${user?.name ?? 'Admin'}! 👑',
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Anda masuk dengan hak akses Super Admin. Kelola kelancaran operasional ekosistem kelompok tani kentang.',
                              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Metrics title
                      const Text(
                        'Statistik Pengguna',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),

                      // Stats Cards Row
                      Row(
                        children: [
                          _buildStatCard('Total Petani', '$_totalUsers', Icons.people, Colors.blue),
                          const SizedBox(width: 16),
                          _buildStatCard('Petani Aktif', '$_activeUsers', Icons.verified_user, Colors.green),
                        ],
                      ),
                      const SizedBox(height: 36),

                      // Admin Modules Grid
                      const Text(
                        'Modul Administrasi',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),

                      GridView.count(
                        crossAxisCount: isDesktop ? 4 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isDesktop ? 1.4 : 1.1,
                        children: [
                          _buildModuleCard(
                            icon: Icons.manage_accounts_rounded,
                            title: 'Kelola Pengguna',
                            desc: 'Registrasi & Impersonasi',
                            color: const Color(0xFF1A7A4A),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserManagementScreen())).then((_) => _loadStats()),
                          ),
                          _buildModuleCard(
                            icon: Icons.edit_note_rounded,
                            title: 'Edit Landing Page',
                            desc: 'Kelola isi CTA depan',
                            color: Colors.blue.shade700,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LandingEditorScreen())).then((_) => _loadStats()),
                          ),
                          _buildModuleCard(
                            icon: Icons.grid_view_rounded,
                            title: 'Kelola Shortcut',
                            desc: 'Modul menu petani',
                            color: Colors.orange.shade800,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomMenusScreen())).then((_) => _loadStats()),
                          ),
                          _buildModuleCard(
                            icon: Icons.rate_review_rounded,
                            title: 'Saran & Kritik',
                            desc: 'Aduan & masukan petani',
                            color: Colors.teal.shade700,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedbackManagementScreen())).then((_) => _loadStats()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: isDesktop
              ? null
              : AppBar(
                  title: const Text('Super Admin Panel'),
                  backgroundColor: const Color(0xFF135835),
                  foregroundColor: Colors.white,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadStats,
                    ),
                  ],
                ),
          drawer: isDesktop ? null : _buildDrawer(context, isInline: false),
          body: Row(
            children: [
              if (isDesktop)
                SizedBox(
                  width: 250,
                  child: _buildDrawer(context, isInline: true),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (isDesktop) _buildDesktopHeader(context),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF135835)))
                          : buildBody(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, {bool isInline = false}) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF135835)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.admin_panel_settings, size: 60, color: Colors.white),
                const SizedBox(height: 10),
                const Text(
                  'Super Admin',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  context.read<AuthProvider>().user?.email ?? 'admin@simhpsk.com',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              if (!isInline) Navigator.pop(context);
              _loadStats();
            },
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts),
            title: const Text('Kelola Pengguna'),
            onTap: () {
              if (!isInline) Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UserManagementScreen())).then((_) => _loadStats());
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: const Text('Edit Landing Page'),
            onTap: () {
              if (!isInline) Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LandingEditorScreen())).then((_) => _loadStats());
            },
          ),
          ListTile(
            leading: const Icon(Icons.grid_view),
            title: const Text('Kelola Menu Shortcut'),
            onTap: () {
              if (!isInline) Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomMenusScreen())).then((_) => _loadStats());
            },
          ),
          ListTile(
            leading: const Icon(Icons.rate_review),
            title: const Text('Saran & Masukan'),
            onTap: () {
              if (!isInline) Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedbackManagementScreen())).then((_) => _loadStats());
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari panel admin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final auth = context.read<AuthProvider>();
              navigator.pop();
              await auth.logout();
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
