import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/dashboard.dart';
import '../login_screen.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/harvest_chart.dart';
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
import '../utils/navigation_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ─── Business Logic (unchanged) ──────────────────────────────────────────────
  late ApiService _apiService;
  DashboardData? _dashboardData;
  List<dynamic> _customMenus = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _stockAlertShown = false;

  // Mobile bottom-nav index
  int _mobileNavIndex = 0;

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
        });

        if (_dashboardData != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showStockThresholdAlert();
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat dashboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _parseHexColor(String hexStr) {
    try {
      return Color(int.parse('FF${hexStr.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return const Color(0xFF27AE60);
    }
  }

  IconData _parseIcon(String iconName) {
    const map = {
      'spa': Icons.spa,
      'agriculture': Icons.agriculture,
      'inventory': Icons.inventory,
      'shopping_cart': Icons.shopping_cart,
      'person': Icons.person,
      'category': Icons.category,
      'monetization_on': Icons.monetization_on,
      'settings': Icons.settings,
      'help': Icons.help,
    };
    return map[iconName] ?? Icons.widgets;
  }

  void _handleCustomMenuTap(BuildContext context, Map<String, dynamic> menu) {
    final url = (menu['url'] ?? '').toString().toLowerCase().trim();
    void push(Widget s) => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => s),
    ).then((_) => _loadDashboard());
    if (url.contains('cost') || url.contains('biaya')) {
      push(const CostsScreen());
    } else if (url.contains('report') ||
        url.contains('laporan') ||
        url.contains('analis')) {
      push(const ReportsScreen());
    } else if (url.contains('setting') || url.contains('pengaturan')) {
      push(const SettingsScreen());
    } else if (url.contains('harvest') || url.contains('panen')) {
      push(const HarvestScreen());
    } else if (url.contains('stock') ||
        url.contains('stok') ||
        url.contains('gudang')) {
      push(const StockScreen());
    } else if (url.contains('sale') || url.contains('jual')) {
      push(const SalesScreen());
    } else if (url.contains('season') || url.contains('musim')) {
      push(const SeasonScreen());
    } else if (url.contains('feedback') || url.contains('ulasan')) {
      push(const FeedbackScreen());
    } else if (url.contains('bot') || url.contains('chat')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatbotScreen()),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            menu['title'] ?? '',
            style: const TextStyle(
              color: AppTheme.green700,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            menu['description'] ?? '',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              final auth = context.read<AuthProvider>();
              nav.pop();
              await auth.logout();
              nav.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ─── Routing ─────────────────────────────────────────────────────────────────
  void _navTo(Widget screen) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => screen),
  ).then((_) => _loadDashboard());

  void _onMobileNavTap(int index) {
    setState(() => _mobileNavIndex = index);
    switch (index) {
      case 1:
        _navTo(const HarvestScreen());
        break;
      case 2:
        _navTo(const StockScreen());
        break;
      case 3:
        _navTo(const SalesScreen());
        break;
      case 4:
        _navTo(const ReportsScreen());
        break;
      case 5:
        _showMobileMore();
        break;
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        if (isDesktop) {
          return _buildDesktop(context);
        }
        return _buildMobile(context);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // DESKTOP
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildDesktop(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.user?.name ?? 'User';
    final email = auth.user?.email ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final now = DateTime.now();
    final dateStr = DateFormat('d MMM yyyy', 'id').format(now);

    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      body: Row(
        children: [
          // ── Sidebar ───────────────────────────────────────────────────────
          AppSidebar(
            userName: name,
            userEmail: email,
            userInitials: initials,
            onLogout: () => _showLogoutDialog(context),
            navItems: _buildNavItems(context, isActive: 'dashboard'),
            secondaryItems: _buildSecondaryNavItems(context),
          ),

          // ── Main ──────────────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                AppHeader(
                  title: 'Dashboard',
                  subtitle: 'Musim 1 · $dateStr',
                  userInitials: initials,
                  onRefresh: _loadDashboard,
                ),
                if (auth.isImpersonating) _buildImpersonationBar(auth),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.green700,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadDashboard,
                          color: AppTheme.green700,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(AppTheme.pageHPad),
                            child: _buildContent(context, isDesktop: true),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // MOBILE
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildMobile(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.user?.name ?? 'User';
    final email = auth.user?.email ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      appBar: AppMobileAppBar(title: 'Dashboard', userInitials: initials),
      drawer: AppDrawer(
        userName: name,
        userEmail: email,
        userInitials: initials,
        onLogout: () => _showLogoutDialog(context),
        navItems: _buildNavItems(context, isActive: 'dashboard'),
        secondaryItems: _buildSecondaryNavItems(context),
      ),
      body: Column(
        children: [
          if (auth.isImpersonating) _buildImpersonationBar(auth),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.green700),
                  )
                : RefreshIndicator(
                    onRefresh: _loadDashboard,
                    color: AppTheme.green700,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
                      child: _buildContent(context, isDesktop: false),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── Nav Items ─────────────────────────────────────────────────────────────

  List<SidebarNavItem> _buildNavItems(
    BuildContext context, {
    required String isActive,
  }) {
    return NavigationHelper.buildNavItems(context, isActive);
  }

  List<SidebarNavItem> _buildSecondaryNavItems(BuildContext context) {
    return NavigationHelper.buildSecondaryNavItems(context, 'dashboard');
  }

  // ─── Main content ────────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, {required bool isDesktop}) {
    final auth = context.watch<AuthProvider>();
    final name = auth.user?.name ?? 'User';
    final farmName = auth.user?.farmName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Banner
        WelcomeBanner(userName: name, farmName: farmName),

        // Error
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          AlertBanner(
            message: 'Gagal memuat data',
            detail: _errorMessage,
            icon: Icons.error_outline_rounded,
            bgColor: AppTheme.red100,
            borderColor: AppTheme.red600,
            textColor: const Color(0xFF7F1D1D),
            iconColor: AppTheme.red600,
          ),
        ],

        // Alert (stock threshold)
        if (_dashboardData != null && _isStockWithinThresholdZone()) ...[
          const SizedBox(height: 16),
          AlertBanner(
            message: _getStockThresholdMessage(),
            detail: _getStockThresholdDetail(),
          ),
        ],

        if (_dashboardData != null) ...[
          const SizedBox(height: 24),

          // Stat cards
          _buildStatCards(context, isDesktop: isDesktop),

          const SizedBox(height: 24),

          // Chart + Financial summary
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 8, child: _buildChartSection()),
                const SizedBox(width: AppTheme.cardGap),
                Expanded(flex: 4, child: _buildFinancialSummary()),
              ],
            )
          else ...[
            _buildChartSection(),
            const SizedBox(height: 16),
            _buildFinancialSummary(),
          ],

          const SizedBox(height: 24),

          // Transactions only
          _buildTransactionsSection(),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  // ─── Stat Cards ──────────────────────────────────────────────────────────────

  Widget _buildStatCards(BuildContext context, {required bool isDesktop}) {
    final stok = _dashboardData!.totalStok;
    final panen = _dashboardData!.totalPanen;
    final rev = _dashboardData!.totalPenjualan;
    final profit = rev - _dashboardData!.totalBiaya;
    final txCount = _dashboardData!.transactions.length;
    final isLow = _dashboardData!.minStock > 0
        ? stok <= _dashboardData!.minStock
        : stok < 5000;
    final minStok = _dashboardData!.minStock;
    final maxStok = _dashboardData!.maxStock;
    final stokProg = ((stok - minStok) / (maxStok - minStok)).clamp(0.0, 1.0);

    final cards = [
      StatCard(
        icon: Icons.inventory_2_outlined,
        iconBg: AppTheme.amber100,
        iconColor: AppTheme.amber600,
        value: '${_formatNumber(stok)} kg',
        label: 'Stok Gudang',
        badgeLabel: isLow ? 'Perhatian' : 'Normal',
        badgeBg: isLow ? AppTheme.amber100 : AppTheme.green100,
        badgeTextColor: isLow ? AppTheme.amber600 : AppTheme.green700,
        badgeIcon: isLow
            ? Icons.warning_amber_rounded
            : Icons.check_circle_outline,
        subLabel: 'Maks: 15.000 kg',
        progressValue: stokProg,
        progressColor: isLow ? AppTheme.amber600 : AppTheme.green500,
        progressMin: '0',
        progressMax: '15.000',
      ),
      StatCard(
        icon: Icons.eco_outlined,
        iconBg: AppTheme.green100,
        iconColor: AppTheme.green700,
        value: '${_formatNumber(panen)} kg',
        label: 'Total Panen',
        badgeLabel: '+8%',
        badgeBg: AppTheme.green100,
        badgeTextColor: AppTheme.green700,
        badgeIcon: Icons.trending_up_rounded,
        subLabel: 'Musim 1 · ${DateTime.now().year}',
      ),
      StatCard(
        icon: Icons.attach_money_rounded,
        iconBg: AppTheme.blue100,
        iconColor: AppTheme.blue600,
        value: _formatCurrencyShort(rev),
        label: 'Total Pendapatan',
        badgeLabel: '$txCount transaksi',
        badgeBg: AppTheme.blue100,
        badgeTextColor: AppTheme.blue600,
        subLabel: 'Musim ini',
      ),
      StatCard(
        icon: Icons.query_stats_rounded,
        iconBg: profit >= 0 ? AppTheme.green100 : AppTheme.red100,
        iconColor: profit >= 0 ? AppTheme.green700 : AppTheme.red600,
        value: _formatCurrencyShort(profit),
        label: 'Estimasi Untung',
        valueColor: profit >= 0 ? AppTheme.green700 : AppTheme.red600,
        subLabel: 'Musim 1 · ${DateTime.now().year}',
      ),
    ];

    if (isDesktop) {
      return Wrap(
        spacing: AppTheme.cardGap,
        runSpacing: AppTheme.cardGap,
        children: cards.map((c) => SizedBox(width: 270, child: c)).toList(),
      );
    }

    return Column(
      children: cards
          .map(
            (c) =>
                Padding(padding: const EdgeInsets.only(bottom: 12), child: c),
          )
          .toList(),
    );
  }

  Widget _buildChartSection() {
    final stats = _dashboardData!.monthlyStats;
    final harvests = stats.map((s) => s.harvest).toList();
    final sales = stats.map((s) => s.sales).toList();
    final labels = stats.map((s) => s.label).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: AppTheme.card,
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: HarvestSalesChart(
        harvestData: harvests,
        salesData: sales,
        labels: labels,
      ),
    );
  }

  // ─── Financial Summary ────────────────────────────────────────────────────────

  Widget _buildFinancialSummary() {
    final revenue = _dashboardData!.totalPenjualan;
    final cost = _dashboardData!.totalBiaya;
    final profit = revenue - cost;

    return SectionCard(
      title: 'Ringkasan Keuangan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _financeTile(
            label: 'Total Pendapatan',
            value: _formatCurrency(revenue),
            color: AppTheme.green700,
            bgColor: AppTheme.green100,
            icon: Icons.trending_up_rounded,
          ),
          const SizedBox(height: 12),
          _financeTile(
            label: 'Biaya Produksi',
            value: _formatCurrency(cost),
            color: AppTheme.red600,
            bgColor: AppTheme.red100,
            icon: Icons.money_off,
          ),
          const SizedBox(height: 12),
          _financeTile(
            label: 'Estimasi Untung',
            value: _formatCurrency(profit),
            color: profit >= 0 ? AppTheme.green700 : AppTheme.red600,
            bgColor: profit >= 0 ? AppTheme.green100 : AppTheme.red100,
            icon: Icons.pie_chart_outline,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _financeTile({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: AppTheme.card,
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _finRow(
    String label,
    String value,
    double progress,
    Color barColor,
    Color tagBg,
    Color tagText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTheme.bodySmall),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tagBg,
                borderRadius: AppTheme.tag,
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tagText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppTheme.cardBorder,
            color: barColor,
          ),
        ),
      ],
    );
  }

  bool _isStockWithinThresholdZone() {
    if (_dashboardData == null) return false;
    final stock = _dashboardData!.totalStok;
    final minStock = _dashboardData!.minStock;
    final maxStock = _dashboardData!.maxStock;
    if (stock <= minStock || stock >= maxStock) {
      return true;
    }

    final lowThreshold = (minStock * 1.15).ceil();
    final highThreshold = (maxStock * 0.85).floor();
    return stock <= lowThreshold || stock >= highThreshold;
  }

  String _getStockThresholdMessage() {
    if (_dashboardData == null) return '';
    final stock = _dashboardData!.totalStok;
    final minStock = _dashboardData!.minStock;
    final maxStock = _dashboardData!.maxStock;

    if (stock <= minStock) {
      return 'Stok gudang telah mencapai batas minimum!';
    }
    if (stock >= maxStock) {
      return 'Stok gudang telah mencapai batas maksimum!';
    }
    if (stock <= (minStock * 1.15).ceil()) {
      return 'Stok gudang mendekati batas minimum.';
    }
    return 'Stok gudang mendekati batas maksimum.';
  }

  String _getStockThresholdDetail() {
    if (_dashboardData == null) return '';
    final stock = _dashboardData!.totalStok;
    final minStock = _dashboardData!.minStock;
    final maxStock = _dashboardData!.maxStock;

    if (stock <= minStock) {
      return 'Stok saat ini ${_formatNumber(stock)} kg, berada di bawah batas minimum ${_formatNumber(minStock)} kg.';
    }
    if (stock >= maxStock) {
      return 'Stok saat ini ${_formatNumber(stock)} kg, telah mencapai batas maksimum ${_formatNumber(maxStock)} kg.';
    }
    if (stock <= (minStock * 1.15).ceil()) {
      return 'Stok saat ini ${_formatNumber(stock)} kg. Pertimbangkan untuk menambah persediaan sebelum mencapai ${_formatNumber(minStock)} kg.';
    }
    return 'Stok saat ini ${_formatNumber(stock)} kg. Pertimbangkan untuk mengatur pengeluaran sebelum mencapai ${_formatNumber(maxStock)} kg.';
  }

  void _showStockThresholdAlert() {
    if (_stockAlertShown || _dashboardData == null) return;
    if (!_isStockWithinThresholdZone()) return;

    _stockAlertShown = true;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getStockThresholdMessage()),
        content: Text(_getStockThresholdDetail()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // ─── Target Section ───────────────────────────────────────────────────────────

  Widget _buildTargetSection() {
    final target = _dashboardData!.targetPanen.toDouble();
    final actual = _dashboardData!.totalPanen.toDouble();
    final pct = target > 0 ? (actual / target).clamp(0.0, 1.0) : 0.0;

    return SectionCard(
      title: 'Target vs Realisasi',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Target: ${_formatNumber(target.toInt())} kg',
            style: AppTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(
            '${_formatNumber(actual.toInt())} kg',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppTheme.cardBorder,
              color: pct >= 1.0 ? AppTheme.green500 : AppTheme.amber600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(pct * 100).toStringAsFixed(1)}% terpenuhi',
            style: AppTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  // ─── Transactions Section ─────────────────────────────────────────────────────

  Widget _buildTransactionsSection() {
    final txns = _dashboardData!.transactions.take(5).toList();

    return SectionCard(
      title: 'Transaksi Stok Terbaru',
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: txns.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Belum ada transaksi.', style: AppTheme.bodySmall),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: txns.length,
              separatorBuilder: (_, b) =>
                  const Divider(height: 1, color: AppTheme.cardBorder),
              itemBuilder: (_, i) {
                final txn = txns[i];
                final isIn = txn.type == 'in';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isIn ? AppTheme.green100 : AppTheme.red100,
                          borderRadius: AppTheme.tag,
                        ),
                        child: Text(
                          isIn ? 'Masuk' : 'Keluar',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isIn ? AppTheme.green700 : AppTheme.red600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${txn.quantity} kg',
                          style: AppTheme.labelBold,
                        ),
                      ),
                      Text(
                        DateFormat('d MMM').format(_safeDate(txn.createdAt)),
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // ─── Custom Menus ─────────────────────────────────────────────────────────────

  Widget _buildCustomMenusSection(
    BuildContext context, {
    required bool isDesktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    final crossAxis = isDesktop
        ? (width >= 1200 ? 4 : 3)
        : (width > 620 ? 2 : 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Menu Tambahan', style: AppTheme.h3),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxis,
            crossAxisSpacing: AppTheme.cardGap,
            mainAxisSpacing: AppTheme.cardGap,
            childAspectRatio: isDesktop ? 2.5 : 1.5,
          ),
          itemCount: _customMenus.length,
          itemBuilder: (_, i) {
            final menu = _customMenus[i];
            final color = _parseHexColor(menu['color'] ?? '#27AE60');
            final icon = _parseIcon(menu['icon'] ?? 'widgets');
            return _CustomMenuCard(
              title: menu['title'] ?? '',
              description: menu['description'] ?? '',
              color: color,
              icon: icon,
              onTap: () =>
                  _handleCustomMenuTap(context, menu as Map<String, dynamic>),
            );
          },
        ),
      ],
    );
  }

  // ─── Impersonation Bar ────────────────────────────────────────────────────────

  Widget _buildImpersonationBar(AuthProvider authProvider) {
    return Container(
      color: Colors.amber.shade800,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      width: double.infinity,
      child: Row(
        children: [
          const Icon(Icons.admin_panel_settings, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Impersonasi: ${authProvider.user?.name}',
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
                    builder: (_) => const SuperAdminDashboardScreen(),
                  ),
                  (_) => false,
                );
              }
            },
            icon: const Icon(Icons.exit_to_app, color: Colors.white, size: 16),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom nav (mobile) ──────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.cardBg,
      selectedItemColor: AppTheme.green700,
      unselectedItemColor: AppTheme.textSecondary,
      selectedLabelStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(fontSize: 10),
      currentIndex: _mobileNavIndex.clamp(0, 5),
      onTap: _onMobileNavTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.agriculture_outlined),
          label: 'Panen',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          label: 'Stok',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart_outlined),
          label: 'Penjualan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_rounded),
          label: 'Laporan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz_rounded),
          label: 'Lainnya',
        ),
      ],
    );
  }

  void _showMobileMore() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),
              _moreItem(
                Icons.calendar_month_outlined,
                'Musim Tanam',
                AppTheme.green700,
                () => _navTo(const SeasonScreen()),
              ),
              _moreItem(
                Icons.attach_money_rounded,
                'Biaya Produksi',
                Colors.orange,
                () => _navTo(const CostsScreen()),
              ),
              _moreItem(
                Icons.smart_toy_outlined,
                'TaniBot AI',
                AppTheme.blue600,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChatbotScreen()),
                ),
              ),
              _moreItem(
                Icons.settings_outlined,
                'Pengaturan',
                AppTheme.textSecondary,
                () => _navTo(const SettingsScreen()),
              ),
              _moreItem(
                Icons.person_outline,
                'Profil',
                AppTheme.textSecondary,
                () => _navTo(const ProfileScreen()),
              ),
              _moreItem(
                Icons.feedback_outlined,
                'Kirim Ulasan',
                AppTheme.textSecondary,
                () => _navTo(const FeedbackScreen()),
              ),
              _moreItem(
                Icons.logout_rounded,
                'Logout',
                AppTheme.red600,
                () => _showLogoutDialog(context),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moreItem(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: AppTheme.textSecondary,
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  String _formatCurrency(int value) =>
      'Rp ${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

  String _formatCurrencyShort(int value) {
    if (value.abs() >= 1000000000)
      return 'Rp ${(value / 1000000000).toStringAsFixed(1)} M';
    if (value.abs() >= 1000000)
      return 'Rp ${(value / 1000000).toStringAsFixed(1)} jt';
    return _formatCurrency(value);
  }

  String _formatNumber(int value) => value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => '.',
  );

  DateTime _safeDate(String? s) => s != null && s.isNotEmpty
      ? (DateTime.tryParse(s) ?? DateTime.now())
      : DateTime.now();

  // Legacy helpers preserved for API compatibility
  // ignore: unused_element
  Color parseHexColor(String hexStr) => _parseHexColor(hexStr);
  // ignore: unused_element
  IconData parseIcon(String iconName) => _parseIcon(iconName);
}

// ─── Custom Menu Card ──────────────────────────────────────────────────────────
class _CustomMenuCard extends StatefulWidget {
  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _CustomMenuCard({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_CustomMenuCard> createState() => _CustomMenuCardState();
}

class _CustomMenuCardState extends State<_CustomMenuCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.08)
                : AppTheme.cardBg,
            border: Border(left: BorderSide(color: widget.color, width: 4)),
            borderRadius: AppTheme.tag,
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.title,
                      style: AppTheme.labelBold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.description,
                      style: AppTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: widget.color,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
