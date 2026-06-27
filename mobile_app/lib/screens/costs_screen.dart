import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/cost.dart';
import '../models/season.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_theme.dart';
import '../login_screen.dart';
import 'add_edit_cost_screen.dart';
import 'home_screen.dart';
import 'season_screen.dart';
import 'harvest_screen.dart';
import 'stock_screen.dart';
import 'sales_screen.dart';
import 'reports_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'feedback_screen.dart';

class CostsScreen extends StatefulWidget {
  const CostsScreen({super.key});

  @override
  State<CostsScreen> createState() => _CostsScreenState();
}

class _CostsScreenState extends State<CostsScreen> {
  final ApiService _apiService = ApiService();
  List<Cost> _costs = [];
  List<Season> _seasons = [];
  int? _selectedSeasonId;
  double _totalCost = 0.0;
  Map<String, double> _costsByCategory = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final seasons = await _apiService.getSeasons();
      final costs = await _apiService.getCosts(seasonId: _selectedSeasonId);
      
      // Calculate totals locally or fetch them
      double sum = 0.0;
      Map<String, double> categories = {'seed': 0.0, 'fertilizer': 0.0, 'pesticide': 0.0, 'other': 0.0};
      for (var c in costs) {
        sum += c.amount;
        categories[c.category] = (categories[c.category] ?? 0.0) + c.amount;
      }

      setState(() {
        _seasons = seasons;
        _costs = costs;
        _totalCost = sum;
        _costsByCategory = categories;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data biaya: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteCost(Cost cost) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Biaya'),
        content: const Text('Apakah Anda yakin ingin menghapus catatan biaya ini?'),
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
      setState(() => _isLoading = true);
      final result = await _apiService.deleteCost(cost.id);
      if (result['success'] == true) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Catatan biaya berhasil dihapus'), backgroundColor: Colors.green),
        );
        _loadData();
      } else {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal menghapus biaya'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getCategoryLabel(String cat) {
    switch (cat) {
      case 'seed': return 'Bibit';
      case 'fertilizer': return 'Pupuk';
      case 'pesticide': return 'Pestisida';
      default: return 'Lainnya';
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'seed': return Icons.spa_rounded;
      case 'fertilizer': return Icons.opacity_rounded;
      case 'pesticide': return Icons.bug_report_rounded;
      default: return Icons.category_rounded;
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'seed': return const Color(0xFF27AE60);
      case 'fertilizer': return const Color(0xFF2D9CDB);
      case 'pesticide': return const Color(0xFFEB5757);
      default: return const Color(0xFFF2994A);
    }
  }

  String _formatRp(double val) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(val);
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
                  title: 'Biaya Produksi',
                  userInitials: initials,
                  onNotificationTap: _loadData,
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
                        title: 'Biaya Produksi',
                        subtitle: 'Kelola data biaya produksi',
                        userInitials: initials,
                        onRefresh: _loadData,
                      ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppTheme.green700))
                          : RefreshIndicator(
                              onRefresh: _loadData,
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final added = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEditCostScreen()));
              if (added == true) _loadData();
            },
            backgroundColor: AppTheme.green700,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Tambah Biaya', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        isActive: true,
        onTap: () {},
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterCard(),
          const SizedBox(height: 16),
          _buildTotalSummaryCard(),
          const SizedBox(height: 20),
          const Text('Rincian per Kategori', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildCategoryBadge('seed'),
              const SizedBox(width: 8),
              _buildCategoryBadge('fertilizer'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildCategoryBadge('pesticide'),
              const SizedBox(width: 8),
              _buildCategoryBadge('other'),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Log Pengeluaran (${_costs.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              TextButton.icon(
                onPressed: () async {
                  final added = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEditCostScreen()));
                  if (added == true) _loadData();
                },
                icon: const Icon(Icons.add, size: 18, color: Color(0xFF27AE60)),
                label: const Text('Tambah', style: TextStyle(color: Color(0xFF27AE60), fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 8),
          if (_costs.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _costs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final cost = _costs[index];
                return _buildCostCard(cost);
              },
            ),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildFilterCard(),
                    const SizedBox(height: 16),
                    _buildTotalSummaryCard(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildCategoryBadge('seed'),
                        const SizedBox(width: 12),
                        _buildCategoryBadge('fertilizer'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildCategoryBadge('pesticide'),
                        const SizedBox(width: 12),
                        _buildCategoryBadge('other'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Daftar Pengeluaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final added = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEditCostScreen()));
                          if (added == true) _loadData();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27AE60), foregroundColor: Colors.white),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Tambah Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (_costs.isEmpty)
                  _buildEmptyState()
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
                          DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Catatan', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Musim Tanam', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: _costs.map((cost) {
                          final color = _getCategoryColor(cost.category);
                          return DataRow(
                            cells: [
                              DataCell(Text(DateFormat('dd MMM yyyy').format(_safeParseDate(cost.date)))),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                                      child: Icon(_getCategoryIcon(cost.category), color: color, size: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(_getCategoryLabel(cost.category), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              DataCell(Text(cost.notes.isNotEmpty ? cost.notes : '-')),
                              DataCell(Text(cost.seasonName)),
                              DataCell(Text(_formatRp(cost.amount), style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold))),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                    tooltip: 'Edit',
                                    onPressed: () async {
                                      final updated = await Navigator.push(context, MaterialPageRoute(builder: (context) => AddEditCostScreen(cost: cost)));
                                      if (updated == true) _loadData();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    tooltip: 'Hapus',
                                    onPressed: () => _deleteCost(cost),
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
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Belum ada catatan biaya untuk periode ini', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _buildCostCard(Cost cost) {
    final color = _getCategoryColor(cost.category);
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(_getCategoryIcon(cost.category), color: color, size: 24),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_getCategoryLabel(cost.category), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(_formatRp(cost.amount), style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cost.notes.isNotEmpty) Text(cost.notes, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 10, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(DateFormat('dd MMM yyyy').format(_safeParseDate(cost.date)), style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  const SizedBox(width: 8),
                  Icon(Icons.eco_outlined, size: 10, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(cost.seasonName, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (val) async {
            if (val == 'edit') {
              final updated = await Navigator.push(context, MaterialPageRoute(builder: (context) => AddEditCostScreen(cost: cost)));
              if (updated == true) _loadData();
            } else if (val == 'delete') {
              _deleteCost(cost);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16), SizedBox(width: 8), Text('Ubah')])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 16, color: Colors.red), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))])),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard() {
    return Card(
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
              const DropdownMenuItem<int?>(value: null, child: Text('Semua Musim Tanam')),
              ..._seasons.map((s) => DropdownMenuItem<int?>(value: s.id, child: Text(s.name))),
            ],
            onChanged: (val) {
              setState(() => _selectedSeasonId = val);
              _loadData();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTotalSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC0392B), Color(0xFFE74C3C)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.money_off_rounded, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text('TOTAL BIAYA PRODUKSI', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_formatRp(_totalCost), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(String cat) {
    final label = _getCategoryLabel(cat);
    final amount = _costsByCategory[cat] ?? 0.0;
    final color = _getCategoryColor(cat);
    final icon = _getCategoryIcon(cat);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text(_formatRp(amount), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  DateTime _safeParseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    return DateTime.tryParse(dateStr) ?? DateTime.now();
  }
}
