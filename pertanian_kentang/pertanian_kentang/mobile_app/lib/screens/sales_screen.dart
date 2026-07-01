import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/sale.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_theme.dart';
import '../login_screen.dart';
import 'home_screen.dart';
import 'season_screen.dart';
import 'harvest_screen.dart';
import 'stock_screen.dart';
import 'costs_screen.dart';
import 'reports_screen.dart';
import 'chatbot_screen.dart';
import 'add_edit_sale_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  late ApiService _apiService;
  List<Sale> _sales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sales = await _apiService.getSales();
      if (mounted) {
        setState(() {
          _sales = sales;
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

  Future<void> _deleteSale(Sale sale) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Penjualan'),
        content: Text('Yakin hapus penjualan ke "${sale.buyerName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final result = await _apiService.deleteSale(sale.id);
      if (result['success'] == true) {
        messenger.showSnackBar(const SnackBar(content: Text('Penjualan berhasil dihapus'), backgroundColor: Colors.green));
        _loadSales();
      } else {
        messenger.showSnackBar(SnackBar(content: Text(result['message'] ?? 'Gagal menghapus'), backgroundColor: Colors.red));
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
                  title: 'Data Penjualan',
                  userInitials: initials,
                  onNotificationTap: _loadSales,
                ),
          drawer: isDesktop
              ? null
              : AppDrawer(
                  userName: name,
                  userEmail: email,
                  userInitials: initials,
                  onLogout: () => _showLogoutDialog(context),
                  navItems: _buildNavItems(context),
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
                    navItems: _buildNavItems(context),
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (isDesktop)
                      AppHeader(
                        title: 'Data Penjualan',
                        subtitle: 'Kelola penjualan dan transaksi',
                        userInitials: initials,
                        onRefresh: _loadSales,
                      ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppTheme.green700))
                          : RefreshIndicator(
                              onRefresh: _loadSales,
                              color: AppTheme.green700,
                              child: _sales.isEmpty
                                  ? _buildEmptyState()
                                  : LayoutBuilder(
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
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppTheme.green700,
            foregroundColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditSaleScreen(onSaved: _loadSales),
                ),
              ).then((_) => _loadSales());
            },
            icon: const Icon(Icons.add),
            label: const Text('Tambah Penjualan', style: TextStyle(fontWeight: FontWeight.bold)),
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
        isActive: true,
        onTap: () {},
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
        icon: Icons.smart_toy_outlined,
        label: 'TaniBot AI',
        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChatbotScreen())),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Tidak ada data penjualan', style: TextStyle(color: Colors.grey.shade600, fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddEditSaleScreen(onSaved: _loadSales)),
            ).then((_) => _loadSales()),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Penjualan Pertama'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27AE60), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _sales.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final sale = _sales[index];
        return _buildSaleCard(sale);
      },
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Daftar Penjualan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                  Text('Total: ${_sales.length} Transaksi', style: const TextStyle(color: Color(0xFF6B7280))),
                ],
              ),
            ),
            const Divider(height: 1),
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
                    DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Pembeli', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Harga/Kg', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: _sales.map((sale) {
                    final statusColor = sale.status == 'completed' ? const Color(0xFF166534) : const Color(0xFF9A3412);
                    final statusBg = sale.status == 'completed' ? const Color(0xFFDCFCE7) : const Color(0xFFFFEDD5);
                    final statusText = sale.status == 'completed' ? 'Lunas' : 'Belum Lunas';

                    return DataRow(
                      cells: [
                        DataCell(Text(DateFormat('dd MMM yyyy').format(_safeParseDate(sale.saleDate)))),
                        DataCell(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sale.buyerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (sale.buyerPhone != null && sale.buyerPhone!.isNotEmpty)
                                Text(sale.buyerPhone!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        DataCell(Text('${sale.quantity} kg')),
                        DataCell(Text(_formatCurrency(sale.pricePerUnit))),
                        DataCell(Text(_formatCurrency(sale.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                            child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                          )
                        ),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                              tooltip: 'Edit',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddEditSaleScreen(sale: sale, onSaved: _loadSales),
                                  ),
                                ).then((_) => _loadSales());
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              tooltip: 'Hapus',
                              onPressed: () => _deleteSale(sale),
                            ),
                          ],
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleCard(Sale sale) {
    final statusColor = sale.status == 'completed' ? Colors.green : Colors.orange;
    final statusText = sale.status == 'completed' ? 'Lunas' : 'Belum Lunas';

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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale.buyerName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sale.buyerPhone != null && sale.buyerPhone!.isNotEmpty)
                      Text(sale.buyerPhone!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor)),
                child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInfoColumn('Jumlah', '${sale.quantity} kg')),
              Expanded(child: _buildInfoColumn('Harga/kg', _formatCurrency(sale.pricePerUnit))),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.withValues(alpha: 0.2))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                Text(_formatCurrency(sale.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoColumn('Tanggal', DateFormat('dd MMM yyyy').format(_safeParseDate(sale.saleDate))),
          if (sale.notes != null && sale.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Catatan', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(sale.notes!, style: const TextStyle(fontSize: 13), maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditSaleScreen(sale: sale, onSaved: _loadSales),
                    ),
                  ).then((_) => _loadSales());
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit'),
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _deleteSale(sale),
                icon: const Icon(Icons.delete, size: 18),
                label: const Text('Hapus'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
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
