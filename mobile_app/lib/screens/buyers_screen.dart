import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sale.dart';

import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_theme.dart';
import '../utils/navigation_helper.dart';
import '../login_screen.dart';

class BuyerSummary {
  final String name;
  final String? phone;
  final int totalQuantity;
  final int totalSpent;
  final int transactionCount;
  final List<Sale> sales;
  final bool hasPiutang;

  BuyerSummary({
    required this.name,
    this.phone,
    required this.totalQuantity,
    required this.totalSpent,
    required this.transactionCount,
    required this.sales,
    required this.hasPiutang,
  });
}

class BuyersScreen extends StatefulWidget {
  const BuyersScreen({super.key});

  @override
  State<BuyersScreen> createState() => _BuyersScreenState();
}

class _BuyersScreenState extends State<BuyersScreen> {
  final ApiService _apiService = ApiService();
  List<BuyerSummary> _buyers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final sales = await _apiService.getSales();
      final Map<String, List<Sale>> grouped = {};

      for (var sale in sales) {
        final key = sale.buyerName.trim().isEmpty ? 'Pembeli Tanpa Nama' : sale.buyerName.trim();
        grouped.putIfAbsent(key, () => []).add(sale);
      }

      final List<BuyerSummary> list = grouped.entries.map((entry) {
        final buyerSales = entry.value;
        int qty = 0;
        int spent = 0;
        String? phone;
        bool piutang = false;

        for (var s in buyerSales) {
          qty += s.quantity;
          spent += s.totalPrice;
          if (s.status != 'completed') {
            piutang = true;
          }
          if ((phone == null || phone.isEmpty) && s.buyerPhone != null && s.buyerPhone!.isNotEmpty) {
            phone = s.buyerPhone;
          }
        }

        return BuyerSummary(
          name: entry.key,
          phone: phone,
          totalQuantity: qty,
          totalSpent: spent,
          transactionCount: buyerSales.length,
          sales: buyerSales,
          hasPiutang: piutang,
        );
      }).toList();

      list.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

      if (mounted) {
        setState(() {
          _buyers = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data pembeli: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
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

  void _showDeleteBuyerNotSupported() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Fitur Belum Tersedia'),
        content: const Text('Penghapusan seluruh riwayat pembeli secara langsung belum didukung. Hapus transaksi penjualan secara individual di menu Penjualan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
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
                  title: 'Manajemen Pembeli',
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
                  navItems: NavigationHelper.buildNavItems(context, 'buyers'),
                  secondaryItems: NavigationHelper.buildSecondaryNavItems(context, 'buyers'),
                ),
          body: Row(
            children: [
              if (isDesktop)
                AppSidebar(
                  userName: name,
                  userEmail: email,
                  userInitials: initials,
                  onLogout: () => _showLogoutDialog(context),
                  navItems: NavigationHelper.buildNavItems(context, 'buyers'),
                  secondaryItems: NavigationHelper.buildSecondaryNavItems(context, 'buyers'),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (isDesktop)
                      AppHeader(
                        title: 'Manajemen Pembeli',
                        subtitle: 'Kelola data pembeli dan riwayat transaksi',
                        userInitials: initials,
                        onRefresh: _loadData,
                      ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppTheme.green700))
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              color: AppTheme.green700,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(28),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildHeaderAction(isDesktop),
                                    const SizedBox(height: 24),
                                    _buildSummaryCards(isDesktop),
                                    const SizedBox(height: 24),
                                    _buyers.isEmpty
                                        ? _buildEmptyState()
                                        : _buildBuyersGrid(isDesktop),
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

  Widget _buildHeaderAction(bool isDesktop) {
    if (!isDesktop) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox.shrink(), // For spacing if we want title here
        ElevatedButton.icon(
          onPressed: () {
            // Functionality to add buyer not strictly defined yet, linking to sales for now or showing toast
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tambahkan pembeli melalui menu Tambah Penjualan')),
            );
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Tambah Pembeli', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.green700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            shadowColor: AppTheme.green700.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(bool isDesktop) {
    final totalPembeli = _buyers.length;
    final pembeliAktif = _buyers.where((b) => b.transactionCount > 0).length;
    final adaPiutang = _buyers.where((b) => b.hasPiutang).length;

    final items = [
      _summaryTile('Total Pembeli', '$totalPembeli', Icons.people_outline, AppTheme.green100, AppTheme.green700),
      _summaryTile('Pembeli Aktif', '$pembeliAktif', Icons.person_add_alt_1_outlined, AppTheme.green100, AppTheme.green700),
      _summaryTile('Ada Piutang', '$adaPiutang', Icons.assignment_late_outlined, AppTheme.green100, AppTheme.green700),
    ];

    if (isDesktop) {
      return Row(
        children: items.map((w) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 16), child: w))).toList()
          ..last = Expanded(child: items.last),
      );
    }
    return Column(
      children: items.map((w) => Padding(padding: const EdgeInsets.only(bottom: 12), child: w)).toList(),
    );
  }

  Widget _summaryTile(String label, String value, IconData icon, Color bg, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Belum ada data pembeli',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyersGrid(bool isDesktop) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 2 : 1, // Using 2 columns for wider cards as per screenshot layout
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        mainAxisExtent: 180, // Fixed height for cards
      ),
      itemCount: _buyers.length,
      itemBuilder: (context, index) {
        final buyer = _buyers[index];
        final badgeColor = buyer.hasPiutang ? const Color(0xFF9A3412) : const Color(0xFF166534);
        final badgeBg = buyer.hasPiutang ? const Color(0xFFFFEDD5) : const Color(0xFFDCFCE7);
        final badgeText = buyer.hasPiutang ? 'Hutang' : 'Lunas';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.cardShadow,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Top Section (Avatar, Info, Actions)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.green700,
                    child: Text(
                      buyer.name.isNotEmpty ? buyer.name[0].toUpperCase() : 'P',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          buyer.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(buyer.phone ?? 'Belum ada kontak', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            const Expanded(
                              child: Text(
                                'Alamat tidak tersedia',
                                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Badges & Actions
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(12)),
                        child: Text(badgeText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: badgeColor)),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _showDeleteBuyerNotSupported(),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppTheme.red100, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.delete_outline, size: 16, color: AppTheme.red600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const Spacer(),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              const Spacer(),
              
              // Bottom Section (Stats)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Transaksi', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('${buyer.transactionCount}x', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Total Pembelian', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(_formatJt(buyer.totalSpent), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.green700)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Formatters ─────────────────────────────────────────────────────────────

  String _formatCurrency(int val) {
    return 'Rp ${val.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
  }

  String _formatJt(int value) {
    if (value >= 1000000) {
      final double result = value / 1000000;
      return 'Rp ${result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 1)} jt';
    }
    return _formatCurrency(value);
  }
}
