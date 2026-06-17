import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/dashboard.dart';
import '../login_screen.dart';
import 'harvest_screen.dart';
import 'stock_screen.dart';
import 'sales_screen.dart';
import 'profile_screen.dart';
import 'costs_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'feedback_screen.dart';
import 'season_screen.dart';
import 'super_admin_dashboard_screen.dart';
import 'chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ApiService _apiService;
  DashboardData? _dashboardData;
  List<dynamic> _customMenus = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getDashboard();
      final menus = await _apiService.getDashboardMenus();
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _customMenus = menus
              .where((m) => m['is_active'] == 1 || m['is_active'] == true)
              .toList();
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat dashboard: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _parseHexColor(String hexStr) {
    try {
      final cleanHex = hexStr.replaceAll('#', '');
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {
      return const Color(0xFF27AE60);
    }
  }

  IconData _parseIcon(String iconName) {
    switch (iconName) {
      case 'spa':
        return Icons.spa;
      case 'agriculture':
        return Icons.agriculture;
      case 'inventory':
        return Icons.inventory;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'person':
        return Icons.person;
      case 'category':
        return Icons.category;
      case 'monetization_on':
        return Icons.monetization_on;
      case 'settings':
        return Icons.settings;
      case 'help':
        return Icons.help;
      default:
        return Icons.widgets;
    }
  }

  void _handleCustomMenuTap(BuildContext context, Map<String, dynamic> menu) {
    final title = menu['title'] ?? '';
    final desc = menu['description'] ?? '';
    final url = menu['url'] ?? '';
    final String cleanUrl = url.toLowerCase().trim();

    if (cleanUrl.contains('cost') ||
        cleanUrl.contains('biaya') ||
        cleanUrl.contains('pengeluaran')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CostsScreen()),
      ).then((_) => _loadDashboard());
    } else if (cleanUrl.contains('report') ||
        cleanUrl.contains('laporan') ||
        cleanUrl.contains('analis') ||
        cleanUrl.contains('grafik') ||
        cleanUrl.contains('chart')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ReportsScreen()),
      ).then((_) => _loadDashboard());
    } else if (cleanUrl.contains('setting') ||
        cleanUrl.contains('pengaturan')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      ).then((_) => _loadDashboard());
    } else if (cleanUrl.contains('harvest') || cleanUrl.contains('panen')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HarvestScreen()),
      ).then((_) => _loadDashboard());
    } else if (cleanUrl.contains('stock') ||
        cleanUrl.contains('stok') ||
        cleanUrl.contains('gudang')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StockScreen()),
      ).then((_) => _loadDashboard());
    } else if (cleanUrl.contains('sale') ||
        cleanUrl.contains('jual') ||
        cleanUrl.contains('penjualan')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SalesScreen()),
      ).then((_) => _loadDashboard());
    } else if (cleanUrl.contains('season') ||
        cleanUrl.contains('musim') ||
        cleanUrl.contains('tanam')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SeasonScreen()),
      ).then((_) => _loadDashboard());
    } else if (cleanUrl.contains('feedback') ||
        cleanUrl.contains('ulasan') ||
        cleanUrl.contains('saran')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FeedbackScreen()),
      ).then((_) => _loadDashboard());
    } else if (cleanUrl.contains('bot') || cleanUrl.contains('chat')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChatbotScreen()),
      ).then((_) => _loadDashboard());
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF135835),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
              if (url.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Tautan: $url',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Tutup',
                style: TextStyle(
                  color: Color(0xFF27AE60),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          backgroundColor: const Color(
            0xFFF3F4F6,
          ), // Light gray background like Laravel
          appBar: isDesktop
              ? null
              : AppBar(
                  title: const Text('SIMHPSK Dashboard'),
                  backgroundColor: const Color(0xFF27AE60),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadDashboard,
                    ),
                  ],
                ),
          drawer: isDesktop ? null : _buildDrawer(context, isInline: false),
          floatingActionButton: isDesktop
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatbotScreen(),
                    ),
                  ),
                  backgroundColor: const Color(0xFF27AE60),
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text(
                    'TaniBot',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
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
                    if (isDesktop) _buildDesktopHeader(context, authProvider),
                    if (authProvider.isImpersonating)
                      _buildImpersonationBar(authProvider),
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF27AE60),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadDashboard,
                              color: const Color(0xFF27AE60),
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(24),
                                child: isDesktop
                                    ? _buildDesktopDashboardLayout(context)
                                    : _buildMobileDashboardLayout(context),
                              ),
                            ),
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

  Widget _buildImpersonationBar(AuthProvider authProvider) {
    return Container(
      color: Colors.amber.shade800,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      width: double.infinity,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Impersonasi: Akun ${authProvider.user?.name}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                final success = await context
                    .read<AuthProvider>()
                    .stopImpersonating();
                if (success && mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SuperAdminDashboardScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(
                Icons.exit_to_app,
                color: Colors.white,
                size: 16,
              ),
              label: const Text(
                'Keluar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context, AuthProvider authProvider) {
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
            'Dashboard',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFF4B5563),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatbotScreen(),
                  ),
                ),
                tooltip: 'TaniBot AI',
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF4B5563)),
                onPressed: _loadDashboard,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDashboardLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWelcomeCard(context),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _errorMessage ?? 'Terjadi kesalahan saat memuat dashboard.',
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),
        ],
        const SizedBox(height: 24),
        _buildStatisticsGrid(),
        const SizedBox(height: 24),
        _buildMenuCards(context),
        if (_customMenus.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildCustomMenuCards(context),
        ],
        const SizedBox(height: 24),
        _buildRecentActivity(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildDesktopDashboardLayout(BuildContext context) {
    if (_dashboardData == null) {
      return _buildDashboardPlaceholder();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4 Stat Cards Row
        Row(
          children: [
            Expanded(
              child: _buildDesktopStatCard(
                'Stok Gudang',
                '${_dashboardData!.totalStok}',
                'kg',
                Icons.inventory_2_outlined,
                const Color(0xFF1A7A4A),
                const Color(0xFFE8F5E9),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDesktopStatCard(
                'Total Panen',
                '${_dashboardData!.targetPanen}',
                'kg',
                Icons.shopping_basket_outlined,
                const Color(0xFFF5A623),
                const Color(0xFFFFF3CD),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDesktopStatCard(
                'Total Pendapatan',
                _formatCurrency(_dashboardData!.totalPenjualan),
                '',
                Icons.trending_up,
                const Color(0xFF27AE60),
                const Color(0xFFE8F5E9),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDesktopStatCard(
                'Estimasi Untung',
                _formatCurrency(
                  _dashboardData!.totalPenjualan - _dashboardData!.totalBiaya,
                ),
                '',
                Icons.monetization_on_outlined,
                (_dashboardData!.totalPenjualan - _dashboardData!.totalBiaya) >=
                        0
                    ? const Color(0xFF27AE60)
                    : const Color(0xFFE74C3C),
                (_dashboardData!.totalPenjualan - _dashboardData!.totalBiaya) >=
                        0
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFEBEE),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Two columns layout
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column (8/12)
            Expanded(
              flex: 8,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Financial Summary (since we don't have chart yet)
                      Expanded(child: _buildDesktopFinancialSummary()),
                      const SizedBox(width: 16),
                      // Target vs Actual
                      Expanded(child: _buildDesktopTargetVsActual()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Custom Menus
                  if (_customMenus.isNotEmpty)
                    _buildDesktopCustomMenus(context),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Right Column (4/12)
            Expanded(
              flex: 4,
              child: Column(children: [_buildDesktopRecentTransactions()]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDashboardPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48.0),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 54,
              color: Colors.orange.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Tidak ada data dashboard yang tersedia.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadDashboard,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
              ),
              child: const Text('Muat Ulang Data'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopStatCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color iconColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$value $unit',
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFinancialSummary() {
    int revenue = _dashboardData!.totalPenjualan;
    int cost = _dashboardData!.totalBiaya;
    int profit = revenue - cost;
    double costPercentage = revenue > 0 ? (cost / revenue) : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Keuangan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Pendapatan',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(revenue),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 1.0,
            backgroundColor: Colors.grey.shade200,
            color: const Color(0xFF27AE60),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 20),
          const Text(
            'Biaya Produksi',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(cost),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: costPercentage.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            color: const Color(0xFFE74C3C),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Untung/Rugi',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(profit),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: profit >= 0
                        ? const Color(0xFF27AE60)
                        : const Color(0xFFE74C3C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTargetVsActual() {
    double target = 1000.0;
    double actual = _dashboardData!.targetPanen
        .toDouble(); // Using targetPanen as actual for now since we don't have total_harvest directly in dashboardData
    double percentage = target > 0 ? (actual / target) : 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Target vs Realisasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Target Panen: ${target.toInt()} kg',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '${actual.toInt()} kg',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            color: percentage >= 1.0
                ? const Color(0xFF27AE60)
                : const Color(0xFFF5A623),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            '${(percentage * 100).toStringAsFixed(1)}% terpenuhi',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopRecentTransactions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transaksi Stok Terbaru',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          if (_dashboardData!.transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Belum ada transaksi',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _dashboardData!.transactions.take(5).length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final txn = _dashboardData!.transactions[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: txn.type == 'in'
                              ? const Color(0xFF198754)
                              : const Color(0xFFDC3545),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          txn.type == 'in' ? 'Masuk' : 'Keluar',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${txn.quantity} kg',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        DateFormat(
                          'dd MMM',
                        ).format(_safeParseDate(txn.createdAt)),
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopCustomMenus(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu Tambahan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.2, // slightly taller cards to avoid text overflow
          ),
          itemCount: _customMenus.length,
          itemBuilder: (context, index) {
            final menu = _customMenus[index];
            final color = _parseHexColor(menu['color'] ?? '#27AE60');
            final icon = _parseIcon(menu['icon'] ?? 'widgets');
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () =>
                    _handleCustomMenuTap(context, menu as Map<String, dynamic>),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.05),
                    border: Border(left: BorderSide(color: color, width: 4)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                menu['title'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Text(
                              menu['description'] ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward, color: color, size: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, {bool isInline = false}) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF27AE60)),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.account_circle,
                      size: 60,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      authProvider.user?.name ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      authProvider.user?.email ?? 'email@example.com',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Color(0xFF27AE60)),
            title: const Text(
              'Dashboard',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: () {
              if (!isInline) Navigator.pop(context);
              _loadDashboard();
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat, color: Color(0xFF27AE60)),
            title: const Text(
              'TaniBot AI',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Asisten Pertanian Kentang',
              style: TextStyle(fontSize: 11),
            ),
            onTap: () {
              if (!isInline) Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatbotScreen()),
              ).then((_) => _loadDashboard());
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Text(
              'PRODUKSI',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month, color: Color(0xFF27AE60)),
            title: const Text(
              'Musim Tanam',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: () {
              if (!isInline) Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SeasonScreen()),
              ).then((_) => _loadDashboard());
            },
          ),
          ListTile(
            leading: const Icon(Icons.agriculture, color: Color(0xFF2E7D32)),
            title: const Text(
              'Pencatatan Panen',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: () {
              if (!isInline) Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HarvestScreen()),
              ).then((_) => _loadDashboard());
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Text(
              'GUDANG',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.inventory, color: Color(0xFF2D9CDB)),
            title: const Text(
              'Stok Gudang',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: () {
              if (!isInline) Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StockScreen()),
              ).then((_) => _loadDashboard());
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Text(
              'KEUANGAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart, color: Color(0xFFF2994A)),
            title: const Text(
              'Penjualan',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: () {
              if (!isInline) Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SalesScreen()),
              ).then((_) => _loadDashboard());
            },
          ),
          ListTile(
            leading: const Icon(Icons.money_off, color: Color(0xFFEB5757)),
            title: const Text(
              'Biaya Produksi',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: () {
              if (!isInline) Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CostsScreen()),
              ).then((_) => _loadDashboard());
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: Text(
              'LAPORAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.analytics, color: Color(0xFF9B51E0)),
            title: const Text(
              'Untung/Rugi',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: () {
              if (!isInline) Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportsScreen(initialTabIndex: 0),
                ),
              ).then((_) => _loadDashboard());
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart, color: Color(0xFF2F80ED)),
            title: const Text(
              'Target vs Realisasi',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: () {
              if (!isInline) Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportsScreen(initialTabIndex: 1),
                ),
              ).then((_) => _loadDashboard());
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings, color: Color(0xFF4F4F4F)),
            title: const Text(
              'Pengaturan',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: () {
              if (!isInline) Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) => _loadDashboard());
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback, color: Color(0xFF4F4F4F)),
            title: const Text(
              'Kirim Ulasan',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Laporkan kendala atau beri saran',
              style: TextStyle(fontSize: 11),
            ),
            onTap: () {
              if (!isInline) Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FeedbackScreen()),
              ).then((_) => _loadDashboard());
            },
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.blueGrey),
            title: const Text(
              'Profil',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: () {
              if (!isInline) Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ).then((_) => _loadDashboard());
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A7A4A), Color(0xFF27AE60)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat datang, ${authProvider.user?.name.split(" ").first ?? 'User'}! 👋',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                authProvider.user?.farmName ?? 'Pertanian Anda',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Peran: ${authProvider.user?.role == "super_admin"
                    ? 'Super Admin'
                    : authProvider.user?.role == "admin"
                    ? 'Admin'
                    : 'Petani'}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsGrid() {
    if (_dashboardData == null) return const SizedBox.shrink();

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard(
          'Stok Saat Ini',
          '${_dashboardData!.totalStok}',
          'kg',
          Icons.inventory,
          const Color(0xFF3498DB),
        ),
        _buildStatCard(
          'Total Penjualan',
          _formatCurrency(_dashboardData!.totalPenjualan),
          '',
          Icons.shopping_cart,
          const Color(0xFF27AE60),
        ),
        _buildStatCard(
          'Total Biaya',
          _formatCurrency(_dashboardData!.totalBiaya),
          '',
          Icons.money_off,
          const Color(0xFFE74C3C),
        ),
        _buildStatCard(
          'Target Panen',
          '${_dashboardData!.targetPanen}',
          'kg',
          Icons.agriculture,
          const Color(0xFFF39C12),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$value $unit',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.0,
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.95,
          children: children,
        ),
      ],
    );
  }

  Widget _buildMenuCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu Dashboard',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildTaniBotCard(context),
        const SizedBox(height: 24),
        _buildCategorySection('PRODUKSI', [
          _buildMenuCard(
            'Musim Tanam',
            Icons.calendar_month,
            const Color(0xFF27AE60),
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SeasonScreen()),
            ).then((_) => _loadDashboard()),
          ),
          _buildMenuCard(
            'Pencatatan Panen',
            Icons.agriculture,
            const Color(0xFF2E7D32),
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HarvestScreen()),
            ).then((_) => _loadDashboard()),
          ),
        ]),
        _buildCategorySection('GUDANG', [
          _buildMenuCard(
            'Stok Gudang',
            Icons.inventory,
            const Color(0xFF2D9CDB),
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StockScreen()),
            ).then((_) => _loadDashboard()),
          ),
        ]),
        _buildCategorySection('KEUANGAN', [
          _buildMenuCard(
            'Penjualan',
            Icons.shopping_cart,
            const Color(0xFFF2994A),
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SalesScreen()),
            ).then((_) => _loadDashboard()),
          ),
          _buildMenuCard(
            'Biaya Produksi',
            Icons.money_off,
            const Color(0xFFEB5757),
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CostsScreen()),
            ).then((_) => _loadDashboard()),
          ),
        ]),
        _buildCategorySection('LAPORAN & UTILITY', [
          _buildMenuCard(
            'Untung/Rugi',
            Icons.analytics,
            const Color(0xFF9B51E0),
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReportsScreen(initialTabIndex: 0),
              ),
            ).then((_) => _loadDashboard()),
          ),
          _buildMenuCard(
            'Target vs Realisasi',
            Icons.bar_chart,
            const Color(0xFF2F80ED),
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReportsScreen(initialTabIndex: 1),
              ),
            ).then((_) => _loadDashboard()),
          ),
          _buildMenuCard(
            'Pengaturan',
            Icons.settings,
            const Color(0xFF4F4F4F),
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ).then((_) => _loadDashboard()),
          ),
        ]),
      ],
    );
  }

  Widget _buildCustomMenuCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shortcut Tambahan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.9,
          ),
          itemCount: _customMenus.length,
          itemBuilder: (context, index) {
            final menu = _customMenus[index];
            final color = _parseHexColor(menu['color'] ?? '#27AE60');
            final icon = _parseIcon(menu['icon'] ?? 'widgets');
            return _buildMenuCard(
              menu['title'] ?? '',
              icon,
              color,
              () => _handleCustomMenuTap(context, menu as Map<String, dynamic>),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTaniBotCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B6F47), Color(0xFFA0826D)],
        ),
        borderRadius: BorderRadius.circular(80),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B6F47).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatbotScreen()),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'TaniBot AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Asisten Pertanian Kentang Anda 🥔',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    if (_dashboardData == null || _dashboardData!.transactions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aktivitas Terbaru',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _dashboardData!.transactions.take(5).length,
            separatorBuilder: (context, index) =>
                Divider(color: Colors.grey.shade200, height: 1),
            itemBuilder: (context, index) {
              final transaction = _dashboardData!.transactions[index];
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: transaction.type == 'in'
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    transaction.type == 'in'
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: transaction.type == 'in' ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(
                  transaction.type == 'in' ? 'Stok Masuk' : 'Stok Keluar',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  DateFormat(
                    'dd MMM yyyy',
                  ).format(_safeParseDate(transaction.createdAt)),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                trailing: Text(
                  '${transaction.quantity} kg',
                  style: TextStyle(
                    color: transaction.type == 'in' ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
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

  String _formatCurrency(int value) {
    return 'Rp ${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
  }

  DateTime _safeParseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    return DateTime.tryParse(dateStr) ?? DateTime.now();
  }
}
