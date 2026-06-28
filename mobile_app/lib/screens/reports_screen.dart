import 'dart:math' as math;
import 'package:flutter/material.dart';
<<<<<<< HEAD
=======
import 'dart:ui' as ui;
>>>>>>> 26f6ebf (update ui menu user terbaru)
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/season.dart';
import '../models/sale.dart';
import '../utils/download_helper.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_theme.dart';
import '../login_screen.dart';
<<<<<<< HEAD
import 'home_screen.dart';
import 'season_screen.dart';
import 'harvest_screen.dart';
import 'stock_screen.dart';
import 'sales_screen.dart';
import 'costs_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'feedback_screen.dart';
=======
import '../utils/navigation_helper.dart';

class MonthlyData {
  final String label;
  final DateTime date;
  double revenue;
  double cost;
  
  MonthlyData(this.label, this.date, this.revenue, this.cost);
  
  double get profit => revenue - cost;
  double get margin => revenue > 0 ? (profit / revenue) * 100 : 0;
}
>>>>>>> 26f6ebf (update ui menu user terbaru)

class ReportsScreen extends StatefulWidget {
  final int initialTabIndex;
  const ReportsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ApiService _apiService = ApiService();
  
  int? _selectedSeasonId;
  List<Season> _seasons = [];
  
  double _totalRevenue = 0.0;
  double _totalCost = 0.0;
  double _profit = 0.0;
  
  List<MonthlyData> _monthlyData = [];
  Map<String, double> _costBreakdown = {};
  
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    try {
      final seasons = await _apiService.getSeasons();
      final pl = await _apiService.getProfitLossReport(seasonId: _selectedSeasonId);
      final costs = await _apiService.getCosts(seasonId: _selectedSeasonId);
      
      // Fetch sales and filter by season
      List<Sale> allSales = [];
      try {
        allSales = await _apiService.getSales();
        if (_selectedSeasonId != null) {
          allSales = allSales.where((s) => s.seasonId == _selectedSeasonId).toList();
        }
      } catch (e) {
        // Ignored if sales api fails
      }
      
      // Calculate monthly data
      Map<String, MonthlyData> monthlyMap = {};
      final monthFormat = DateFormat('MMM yyyy');
      
      for (var c in costs) {
        try {
          final dt = DateTime.parse(c.date);
          final label = monthFormat.format(dt);
          monthlyMap.putIfAbsent(label, () => MonthlyData(label, DateTime(dt.year, dt.month), 0, 0));
          monthlyMap[label]!.cost += c.amount;
        } catch (_) {}
      }
      
      for (var s in allSales) {
        try {
          final dt = DateTime.parse(s.saleDate);
          final label = monthFormat.format(dt);
          monthlyMap.putIfAbsent(label, () => MonthlyData(label, DateTime(dt.year, dt.month), 0, 0));
          monthlyMap[label]!.revenue += s.totalPrice;
        } catch (_) {}
      }
      
      final sortedMonths = monthlyMap.values.toList()..sort((a, b) => a.date.compareTo(b.date));
      
      // Calculate breakdown
      double bibitPupuk = 0;
      double pestisida = 0;
      double operasional = 0;
      
      for (var c in costs) {
        final cat = c.category.toLowerCase();
        if (cat == 'seed' || cat == 'fertilizer') {
          bibitPupuk += c.amount;
        } else if (cat == 'pesticide') {
          pestisida += c.amount;
        } else {
          operasional += c.amount;
        }
      }
      
      if (mounted) {
        setState(() {
          _seasons = seasons;
          if (pl != null) {
            _totalRevenue = (pl['total_revenue'] as num? ?? 0).toDouble();
            _totalCost = (pl['total_cost'] as num? ?? 0).toDouble();
            _profit = (pl['profit'] as num? ?? 0).toDouble();
          } else {
            _totalRevenue = 0;
            _totalCost = 0;
            _profit = 0;
          }
          
          _monthlyData = sortedMonths;
          _costBreakdown = {
            'Bibit & Pupuk': bibitPupuk,
            'Pestisida': pestisida,
            'Operasional & Upah': operasional,
          };
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat laporan: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _exportPdf() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: AppTheme.green700),
              SizedBox(width: 20),
              Expanded(child: Text('Sedang membuat PDF...\nMohon tunggu sebentar.')),
            ],
          ),
        ),
      );
    }

    try {
      final pdfBytes = await _apiService.downloadProfitLossReportPdf(seasonId: _selectedSeasonId);
      final filename = _selectedSeasonId != null
          ? 'Laporan_Laba_Rugi_Musim_$_selectedSeasonId.pdf'
          : 'Laporan_Laba_Rugi_Semua_Musim.pdf';

      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      setState(() => _isExporting = false);

      if (pdfBytes != null && pdfBytes.isNotEmpty) {
        downloadFile(pdfBytes, filename);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Laporan PDF berhasil diunduh!'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengunduh PDF: Data kosong'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      setState(() => _isExporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal ekspor PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final authProvider = context.read<AuthProvider>();
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Apakah Anda yakin ingin keluar dari panel admin?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
                await authProvider.logout();
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  String _formatJt(double value) {
    final double result = value / 1000000;
    return 'Rp ${result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 1)} jt';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final name = user?.name ?? 'Super Admin';
    final email = user?.email ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'S';

<<<<<<< HEAD
    final tabBar = TabBar(
      controller: _tabController,
      indicatorColor: AppTheme.green700,
      indicatorWeight: 3,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      unselectedLabelColor: AppTheme.textSecondary,
      labelColor: AppTheme.textPrimary,
      tabs: const [
        Tab(text: 'Laba / Rugi'),
        Tab(text: 'Realisasi Target'),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
=======
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final selectedSeasonName = _selectedSeasonId != null 
            ? _seasons.firstWhere((s) => s.id == _selectedSeasonId, orElse: () => Season(id: 0, name: 'Semua Musim Tanam', startDate: '', endDate: '', status: '')).name
            : 'Semua Musim Tanam';
            
        final monthRangeStr = _monthlyData.isNotEmpty 
            ? '${_monthlyData.first.label.split(' ')[0]} - ${_monthlyData.last.label.split(' ')[0]} ${_monthlyData.last.label.split(' ')[1]}'
            : 'Belum ada data';
>>>>>>> 26f6ebf (update ui menu user terbaru)

        return Scaffold(
          backgroundColor: AppTheme.pageBg,
          appBar: isDesktop
              ? null
              : AppMobileAppBar(
<<<<<<< HEAD
                  title: 'Laporan & Analitik',
=======
                  title: 'Laporan',
>>>>>>> 26f6ebf (update ui menu user terbaru)
                  userInitials: initials,
                  onNotificationTap: _loadReportData,
                ),
          drawer: isDesktop
              ? null
              : AppDrawer(
                  userName: name,
                  userEmail: email,
                  userInitials: initials,
                  onLogout: () => _showLogoutDialog(context),
<<<<<<< HEAD
                  navItems: _buildNavItems(context),
                ),
          body: Row(
            children: [
              if (isDesktop)
                AppSidebar(
                  userName: name,
                  userEmail: email,
                  userInitials: initials,
                  onLogout: () => _showLogoutDialog(context),
                  navItems: _buildNavItems(context),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (isDesktop)
                      AppHeader(
                        title: 'Laporan & Analitik',
                        subtitle: 'Analisis laba rugi dan realisasi target',
                        userInitials: initials,
                        onRefresh: _loadReportData,
                        actions: [
                          if (_isExporting)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: AppTheme.green700, strokeWidth: 2),
                                ),
                              ),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf_rounded),
                              color: AppTheme.textSecondary,
                              tooltip: 'Unduh PDF',
                              onPressed: _exportPdf,
                            ),
                        ],
                      ),
                    Container(
                      width: double.infinity,
                      color: AppTheme.cardBg,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: tabBar,
                    ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppTheme.green700))
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildProfitLossTab(),
                                _buildTargetVsActualTab(),
                              ],
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

  List<SidebarNavItem> _buildNavItems(BuildContext context) {
    return [
      SidebarNavItem(
        icon: Icons.grid_view_rounded,
        label: 'Dashboard',
        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())),
      ),
      SidebarNavItem(
        icon: Icons.calendar_month_outlined,
        label: 'Musim Tanam',
        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SeasonScreen())),
      ),
      SidebarNavItem(
        icon: Icons.agriculture_outlined,
        label: 'Pencatatan Panen',
        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HarvestScreen())),
      ),
      SidebarNavItem(
        icon: Icons.inventory_2_outlined,
        label: 'Stok Gudang',
        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StockScreen())),
      ),
      SidebarNavItem(
        icon: Icons.shopping_cart_outlined,
        label: 'Penjualan',
        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SalesScreen())),
      ),
      SidebarNavItem(
        icon: Icons.attach_money_rounded,
        label: 'Biaya Produksi',
        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CostsScreen())),
      ),
      SidebarNavItem(
        icon: Icons.person,
        label: 'Profil',
        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
      ),
      SidebarNavItem(
        icon: Icons.settings,
        label: 'Pengaturan',
        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
      ),
      SidebarNavItem(
        icon: Icons.bar_chart,
        label: 'Laporan',
        isActive: true,
        onTap: () {},
      ),
    ];
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final authProvider = context.read<AuthProvider>();
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Apakah Anda yakin ingin keluar dari panel admin?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
                await authProvider.logout();
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfitLossTab() {
    if (!_isPLReady) return const SizedBox.shrink();

    final costRatio = _totalRevenue > 0 ? (_totalCost / _totalRevenue) : 0.0;
    final profitRatio = _totalRevenue > 0 ? (_profit / _totalRevenue) : 0.0;
    final isLoss = _profit < 0;

    return RefreshIndicator(
      onRefresh: _loadReportData,
      color: const Color(0xFF27AE60),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Season filter and Export PDF Button
                isDesktop
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 300,
                            child: Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int?>(
                                    value: _selectedSeasonId,
                                    isExpanded: true,
                                    hint: const Text('Semua Musim Tanam'),
                                    items: [
                                      const DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text('Semua Musim Tanam'),
                                      ),
                                      ..._seasons.map((s) => DropdownMenuItem<int?>(
                                            value: s.id,
                                            child: Text(s.name),
                                          )),
                                    ],
                                    onChanged: (val) {
                                      setState(() => _selectedSeasonId = val);
                                      _loadReportData();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isExporting ? null : _exportPdf,
                            icon: _isExporting
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.picture_as_pdf_rounded),
                            label: Text(_isExporting ? 'Membuat PDF...' : 'Ekspor PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isExporting ? Colors.grey : const Color(0xFF27AE60),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 2,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int?>(
                                  value: _selectedSeasonId,
                                  isExpanded: true,
                                  hint: const Text('Semua Musim Tanam'),
                                  items: [
                                    const DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text('Semua Musim Tanam'),
                                    ),
                                    ..._seasons.map((s) => DropdownMenuItem<int?>(
                                          value: s.id,
                                          child: Text(s.name),
                                        )),
                                  ],
                                  onChanged: (val) {
                                    setState(() => _selectedSeasonId = val);
                                    _loadReportData();
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isExporting ? null : _exportPdf,
                              icon: _isExporting
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.picture_as_pdf_rounded),
                              label: Text(_isExporting ? 'Membuat PDF...' : 'Ekspor PDF'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isExporting ? Colors.grey : const Color(0xFF27AE60),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                SizedBox(height: isDesktop ? 32 : 20),

                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildPLMainCard(isLoss),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Rasio Keuangan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 16),
                            _buildRasioCard(costRatio, profitRatio, isLoss),
                            const SizedBox(height: 24),
                            const Text('Detail Neraca', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _buildBalanceDetailTile(icon: Icons.monetization_on_rounded, color: const Color(0xFF27AE60), title: 'Total Pendapatan', value: _formatRp(_totalRevenue), subtitle: 'Kotor')),
                                const SizedBox(width: 16),
                                Expanded(child: _buildBalanceDetailTile(icon: Icons.money_off_rounded, color: const Color(0xFFEB5757), title: 'Total Pengeluaran', value: _formatRp(_totalCost), subtitle: 'Lahan')),
                                const SizedBox(width: 16),
                                Expanded(child: _buildBalanceDetailTile(icon: Icons.scale_rounded, color: const Color(0xFF2D9CDB), title: 'Bobot Panen', value: '$_totalHarvest kg', subtitle: 'Aktual')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPLMainCard(isLoss),
                      const SizedBox(height: 24),
                      const Text('Rasio Keuangan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 12),
                      _buildRasioCard(costRatio, profitRatio, isLoss),
                      const SizedBox(height: 24),
                      const Text('Detail Neraca', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 12),
                      _buildBalanceDetailTile(icon: Icons.monetization_on_rounded, color: const Color(0xFF27AE60), title: 'Total Pendapatan Kotor', value: _formatRp(_totalRevenue), subtitle: 'Penjualan kentang terverifikasi'),
                      const SizedBox(height: 12),
                      _buildBalanceDetailTile(icon: Icons.money_off_rounded, color: const Color(0xFFEB5757), title: 'Total Pengeluaran Lahan', value: _formatRp(_totalCost), subtitle: 'Bibit, pupuk, pestisida, & lainnya'),
                      const SizedBox(height: 12),
                      _buildBalanceDetailTile(icon: Icons.scale_rounded, color: const Color(0xFF2D9CDB), title: 'Total Bobot Panen', value: '$_totalHarvest kg', subtitle: 'Akumulasi ubi kentang yang dipanen'),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPLMainCard(bool isLoss) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLoss 
              ? [const Color(0xFFC0392B), const Color(0xFFE74C3C)]
              : [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isLoss ? Colors.red : Colors.green).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            isLoss ? 'TOTAL KERUGIAN BERSIH' : 'TOTAL KEUNTUNGAN BERSIH',
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          Text(
            _formatRp(_profit.abs()),
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isLoss ? Icons.trending_down : Icons.trending_up, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  isLoss ? 'Beban biaya tinggi' : 'Margin keuntungan sehat',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
=======
                  navItems: NavigationHelper.buildNavItems(context, 'reports'),
                  secondaryItems: NavigationHelper.buildSecondaryNavItems(context, 'reports'),
>>>>>>> 26f6ebf (update ui menu user terbaru)
                ),
          body: Row(
            children: [
              if (isDesktop)
                AppSidebar(
                  userName: name,
                  userEmail: email,
                  userInitials: initials,
                  onLogout: () => _showLogoutDialog(context),
                  navItems: NavigationHelper.buildNavItems(context, 'reports'),
                  secondaryItems: NavigationHelper.buildSecondaryNavItems(context, 'reports'),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (isDesktop)
                      AppHeader(
                        title: 'Laporan',
                        subtitle: '$selectedSeasonName • $monthRangeStr',
                        userInitials: initials,
                        onRefresh: _loadReportData,
                      ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppTheme.green700))
                          : RefreshIndicator(
                              onRefresh: _loadReportData,
                              color: AppTheme.green700,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildTitleAndExportRow(selectedSeasonName, monthRangeStr, isDesktop),
                                    const SizedBox(height: 24),
                                    _buildTopStatsCards(isDesktop),
                                    const SizedBox(height: 24),
                                    if (isDesktop)
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(flex: 2, child: _buildChartCard()),
                                          const SizedBox(width: 24),
                                          Expanded(flex: 1, child: _buildCostDetailCard()),
                                        ],
                                      )
                                    else
                                      Column(
                                        children: [
                                          _buildChartCard(),
                                          const SizedBox(height: 24),
                                          _buildCostDetailCard(),
                                        ],
                                      ),
                                    const SizedBox(height: 24),
                                    _buildMonthlyTable(isDesktop),
                                  ],
                                ),
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

  Widget _buildTitleAndExportRow(String seasonName, String monthRange, bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Laporan Untung/Rugi', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
            const SizedBox(height: 4),
            Text('$seasonName • $monthRange', style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _isExporting ? null : _exportPdf,
          icon: _isExporting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.picture_as_pdf_outlined, size: 20),
          label: const Text('Ekspor PDF', style: TextStyle(fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.cardBorder),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildTopStatsCards(bool isDesktop) {
    final margin = _totalRevenue > 0 ? (_profit / _totalRevenue) * 100 : 0.0;
    
    final cards = [
      Expanded(child: _buildStatCard(
        title: 'Total Pendapatan',
        amount: _formatJt(_totalRevenue),
        color: const Color(0xFFE2F5E9),
        textColor: const Color(0xFF166534),
        icon: Icons.trending_up,
      )),
      SizedBox(width: isDesktop ? 24 : 12),
      Expanded(child: _buildStatCard(
        title: 'Total Biaya',
        amount: _formatJt(_totalCost),
        color: const Color(0xFFFFE4E6),
        textColor: const Color(0xFF9F1239),
        icon: Icons.trending_down,
      )),
      SizedBox(width: isDesktop ? 24 : 12),
      Expanded(child: _buildStatCard(
        title: 'Laba Bersih',
        amount: _formatJt(_profit),
        color: const Color(0xFFE5F7ED),
        textColor: const Color(0xFF065F46),
        icon: Icons.attach_money,
        subtitle: 'Margin: ${margin.toStringAsFixed(1)}%',
      )),
    ];
    
    return isDesktop
        ? Row(children: cards)
        : Column(
            children: [
              Row(children: [cards[0], cards[1], cards[2]]),
              const SizedBox(height: 12),
              cards[4]
            ],
          );
  }

  Widget _buildStatCard({required String title, required String amount, required Color color, required Color textColor, required IconData icon, String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(amount, style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.w800)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500)),
          ]
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tren Bulanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: _monthlyData.isEmpty
                ? const Center(child: Text('Belum ada data bulanan', style: TextStyle(color: AppTheme.textSecondary)))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: _BarChartPainter(data: _monthlyData),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostDetailCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detail Biaya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 24),
          ..._costBreakdown.entries.map((e) {
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                    Text(_formatJt(e.value), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: Color(0xFFF3F4F6)),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMonthlyTable(bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Rincian per Bulan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          ),
          Container(
            color: const Color(0xFFF9FAFB),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('BULAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5))),
                Expanded(flex: 2, child: Text('PENDAPATAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5))),
                Expanded(flex: 2, child: Text('BIAYA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5))),
                Expanded(flex: 2, child: Text('LABA BERSIH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5))),
                Expanded(flex: 1, child: Text('MARGIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          ..._monthlyData.map((data) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(data.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(_formatJt(data.revenue), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF166534))),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(_formatJt(data.cost), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(_formatJt(data.profit), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('${data.margin.toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF166534), fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<MonthlyData> data;

  _BarChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final count = data.length;
    double maxVal = 0;
    for (var d in data) {
      if (d.revenue > maxVal) maxVal = d.revenue;
      if (d.cost > maxVal) maxVal = d.cost;
    }
    
    if (maxVal == 0) maxVal = 10000000;
    
    // Draw Grid Lines (Y-Axis)
    final gridPaint = Paint()
      ..color = const Color(0xFFF3F4F6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    
    const double bottomPadding = 30.0;
    const double leftPadding = 40.0;
    
    final chartHeight = size.height - bottomPadding;
    final chartWidth = size.width - leftPadding;
    
    // Draw horizontal grid lines and labels
    for (int i = 0; i <= 4; i++) {
      final y = chartHeight - (i * chartHeight / 4);
      final value = (i * maxVal / 4);
      
      // Draw dashed line (simplification: solid line)
      _drawDashedLine(canvas, Offset(leftPadding, y), Offset(size.width, y), gridPaint);
      
      final label = '${(value / 1000000).toStringAsFixed(0)}jt';
      textPainter.text = TextSpan(text: label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10));
      textPainter.layout();
      textPainter.paint(canvas, Offset(leftPadding - textPainter.width - 8, y - textPainter.height / 2));
    }
    
    // Draw bars
    final slotWidth = chartWidth / count;
    final barWidth = slotWidth * 0.3; // 30% for each bar
    final barGap = slotWidth * 0.1;   // 10% gap between revenue/cost
    
    final revenuePaint = Paint()..color = const Color(0xFF4ADE80); // Light Green
    final costPaint = Paint()..color = const Color(0xFFF87171); // Light Red
    
    for (int i = 0; i < count; i++) {
      final d = data[i];
      final slotStartX = leftPadding + (i * slotWidth);
      final centerX = slotStartX + (slotWidth / 2);
      
      final revHeight = (d.revenue / maxVal) * chartHeight;
      final costHeight = (d.cost / maxVal) * chartHeight;
      
      // Revenue Bar (Left)
      final revRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - barWidth - (barGap/2), chartHeight - revHeight, barWidth, revHeight),
        const Radius.circular(2)
      );
      canvas.drawRRect(revRect, revenuePaint);
      
      // Cost Bar (Right)
      final costRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + (barGap/2), chartHeight - costHeight, barWidth, costHeight),
        const Radius.circular(2)
      );
      canvas.drawRRect(costRect, costPaint);
      
      // X-Axis Label (e.g. 'Jan')
      final monthName = d.label.split(' ')[0];
      textPainter.text = TextSpan(text: monthName, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10));
      textPainter.layout();
      textPainter.paint(canvas, Offset(centerX - textPainter.width / 2, chartHeight + 10));
    }
  }
  
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLen = 4.0;
    const gapLen = 4.0;
    double drawn = 0;
    final totalLen = end.dx - start.dx;
    while (drawn < totalLen) {
      canvas.drawLine(Offset(start.dx + drawn, start.dy), Offset(start.dx + math.min(drawn + dashLen, totalLen), start.dy), paint);
      drawn += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter oldDelegate) => true;
}
