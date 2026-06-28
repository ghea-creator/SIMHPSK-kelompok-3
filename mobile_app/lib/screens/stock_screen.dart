import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/stock.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_theme.dart';
import '../login_screen.dart';
<<<<<<< HEAD
=======
import '../utils/navigation_helper.dart';
>>>>>>> 26f6ebf (update ui menu user terbaru)
import 'home_screen.dart';
import 'season_screen.dart';
import 'harvest_screen.dart';
import 'sales_screen.dart';
import 'costs_screen.dart';
import 'reports_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  late ApiService _apiService;
  StockData? _stockData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadStock();
  }

  Future<void> _loadStock() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stock = await _apiService.getStock();
      if (mounted) {
        setState(() {
          _stockData = stock;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    final name = user?.name ?? 'Super Admin';
    final email = user?.email ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          backgroundColor: AppTheme.pageBg,
          appBar: isDesktop
              ? null
              : AppMobileAppBar(
                  title: 'Data Stok',
                  userInitials: initials,
                  onNotificationTap: _loadStock,
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
=======
                  navItems: NavigationHelper.buildNavItems(context, 'stock'),
                  secondaryItems: NavigationHelper.buildSecondaryNavItems(context, 'stock'),
>>>>>>> 26f6ebf (update ui menu user terbaru)
                ),
          body: Row(
            children: [
              if (isDesktop)
                SizedBox(
                  width: AppTheme.sidebarExpandedW,
                  child: AppSidebar(
                    userName: name,
                    userEmail: email,
                    userInitials: initials,
                    onLogout: () => _showLogoutDialog(context),
<<<<<<< HEAD
                    navItems: _buildNavItems(context),
=======
                    navItems: NavigationHelper.buildNavItems(context, 'stock'),
                    secondaryItems: NavigationHelper.buildSecondaryNavItems(context, 'stock'),
>>>>>>> 26f6ebf (update ui menu user terbaru)
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (isDesktop)
                      AppHeader(
                        title: 'Data Stok',
                        subtitle: 'Pantau stok dan riwayat transaksi',
                        userInitials: initials,
                        onRefresh: _loadStock,
                      ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppTheme.green700))
                          : RefreshIndicator(
                              onRefresh: _loadStock,
                              color: AppTheme.green700,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxWidth > 800) {
                                    return _buildDesktopLayout();
                                  }
                                  return _buildMobileLayout();
                                },
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
        icon: Icons.bar_chart_rounded,
        label: 'Laporan',
        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
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
        icon: Icons.inventory_2,
        label: 'Data Stok',
        isActive: true,
        onTap: () {},
      ),
    ];
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_stockData != null) ...[
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildTransactionsList(),
          ] else ...[
            _buildEmptyState(),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_stockData != null) ...[
            _buildDesktopSummaryCards(),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Riwayat Transaksi Stok', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                  ),
                  const Divider(height: 1),
                  if (_stockData!.transactions.isEmpty)
                    const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Belum ada transaksi', style: TextStyle(color: Colors.grey))))
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 48),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                            return const Color(0xFFF9FAFB);
                          }),
                          dataRowMaxHeight: 65,
                          columns: const [
                            DataColumn(label: Text('Tanggal Transaksi', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Jenis Transaksi', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Jumlah (Kg)', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _stockData!.transactions.map((transaction) {
                            final isIncoming = transaction.type == 'in';
                            final color = isIncoming ? const Color(0xFF166534) : const Color(0xFF991B1B);
                            final bgColor = isIncoming ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
                            final label = isIncoming ? 'Stok Masuk' : 'Stok Keluar';

                            return DataRow(
                              cells: [
                                DataCell(Text(DateFormat('dd MMM yyyy, HH:mm').format(_safeParseDate(transaction.transactionDate)))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(isIncoming ? Icons.arrow_downward : Icons.arrow_upward, size: 14, color: color),
                                        const SizedBox(width: 4),
                                        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                                DataCell(Text('${transaction.quantity} kg', style: const TextStyle(fontWeight: FontWeight.bold))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            _buildEmptyState(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Tidak ada data stok', style: TextStyle(color: Colors.grey.shade600, fontSize: 18, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _buildSummaryCard('Masuk', '${_stockData!.totalIncoming} kg', Icons.arrow_downward, Colors.green),
        _buildSummaryCard('Keluar', '${_stockData!.totalOutgoing} kg', Icons.arrow_upward, Colors.red),
        _buildSummaryCard('Saat Ini', '${_stockData!.currentStock} kg', Icons.inventory, Colors.blue),
      ],
    );
  }

  Widget _buildDesktopSummaryCards() {
    return Row(
      children: [
        Expanded(child: _buildDesktopSummaryCard('Total Masuk', '${_stockData!.totalIncoming} kg', Icons.arrow_downward, const Color(0xFF1A7A4A), const Color(0xFFE8F5E9))),
        const SizedBox(width: 16),
        Expanded(child: _buildDesktopSummaryCard('Total Keluar', '${_stockData!.totalOutgoing} kg', Icons.arrow_upward, const Color(0xFFE74C3C), const Color(0xFFFFEBEE))),
        const SizedBox(width: 16),
        Expanded(child: _buildDesktopSummaryCard('Stok Saat Ini', '${_stockData!.currentStock} kg', Icons.inventory_2, const Color(0xFF3B82F6), const Color(0xFFEFF6FF))),
      ],
    );
  }

  Widget _buildDesktopSummaryCard(String label, String value, IconData icon, Color iconColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Color(0xFF111827), fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_stockData!.transactions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Riwayat Transaksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _stockData!.transactions.length,
            separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200, height: 1),
            itemBuilder: (context, index) => _buildTransactionTile(_stockData!.transactions[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(StockTransaction transaction) {
    final isIncoming = transaction.type == 'in';
    final color = isIncoming ? Colors.green : Colors.red;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(isIncoming ? Icons.arrow_downward : Icons.arrow_upward, color: color),
      ),
      title: Text(isIncoming ? 'Stok Masuk' : 'Stok Keluar', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(DateFormat('dd MMM yyyy, HH:mm').format(_safeParseDate(transaction.transactionDate)), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      trailing: Text('${transaction.quantity} kg', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  DateTime _safeParseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    return DateTime.tryParse(dateStr) ?? DateTime.now();
  }
}
