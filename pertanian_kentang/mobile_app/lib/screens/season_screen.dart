import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/season.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_header.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_theme.dart';
import '../login_screen.dart';
import '../utils/navigation_helper.dart';

class SeasonScreen extends StatefulWidget {
  const SeasonScreen({super.key});

  @override
  State<SeasonScreen> createState() => _SeasonScreenState();
}

class _SeasonScreenState extends State<SeasonScreen> {
  final _apiService = ApiService();
  List<Season> _seasons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSeasons();
  }

  Future<void> _loadSeasons() async {
    setState(() => _isLoading = true);
    try {
      final seasons = await _apiService.getSeasons();
      setState(() {
        _seasons = seasons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showSeasonForm({Season? season}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SeasonFormBottomSheet(
        apiService: _apiService,
        season: season,
        existingSeasons: _seasons,
        onSuccess: (_) {
          _loadSeasons();
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _deleteSeason(Season season) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Musim Tanam'),
        content: Text('Yakin hapus musim tanam "${season.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _apiService.deleteSeason(season.id);
      if (result['success'] == true) {
        _loadSeasons();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Musim tanam berhasil dihapus')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Gagal menghapus')),
          );
        }
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
                  title: 'Musim Tanam',
                  userInitials: initials,
                  onNotificationTap: _loadSeasons,
                ),
          drawer: isDesktop
              ? null
              : AppDrawer(
                  userName: name,
                  userEmail: email,
                  userInitials: initials,
                  onLogout: () => _showLogoutDialog(context),
                  navItems: NavigationHelper.buildNavItems(context, 'season'),
                  secondaryItems: NavigationHelper.buildSecondaryNavItems(context, 'season'),
                ),
          body: Row(
            children: [
              if (isDesktop)
                AppSidebar(
                  userName: name,
                  userEmail: email,
                  userInitials: initials,
                  onLogout: () => _showLogoutDialog(context),
                  navItems: NavigationHelper.buildNavItems(context, 'season'),
                  secondaryItems: NavigationHelper.buildSecondaryNavItems(context, 'season'),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (isDesktop)
                      AppHeader(
                        title: 'Musim Tanam',
                        subtitle: 'Kelola musim tanam dan target panen',
                        userInitials: initials,
                        onRefresh: _loadSeasons,
                      ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppTheme.green700))
                          : RefreshIndicator(
                              onRefresh: _loadSeasons,
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
          floatingActionButton: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) return const SizedBox.shrink();
              return FloatingActionButton.extended(
                onPressed: () => _showSeasonForm(),
                backgroundColor: AppTheme.green700,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Tambah Musim',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              );
            },
          ),
        );
      },
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
          Icon(Icons.calendar_month, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Belum ada musim tanam', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Mulai dengan menambahkan musim tanam baru.', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    if (_seasons.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _seasons.length,
      itemBuilder: (context, index) {
        final season = _seasons[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppTheme.cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(season.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                    ),
                    _buildStatusBadge(season.status),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '${_formatDateString(season.startDate)} – ${_formatDateString(season.endDate)}',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.agriculture_outlined, size: 14, color: AppTheme.green700),
                    const SizedBox(width: 6),
                    Text(
                      'Total Panen: ${_formatNumber(season.totalPanen)} kg',
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.green700, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _ActionBtn(
                      icon: Icons.edit_outlined,
                      color: AppTheme.blue600,
                      bgColor: AppTheme.blue100,
                      tooltip: 'Edit',
                      onTap: () => _showSeasonForm(season: season),
                    ),
                    const SizedBox(width: 8),
                    _ActionBtn(
                      icon: Icons.delete_outline,
                      color: AppTheme.red600,
                      bgColor: AppTheme.red100,
                      tooltip: 'Hapus',
                      onTap: () => _deleteSeason(season),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    final totalMusim = _seasons.length;
    final musimAktif = _seasons.where((s) => s.status == 'active').length;
    final musimSelesai = _seasons.where((s) => s.status == 'completed').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Page Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Musim Tanam',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kelola periode musim tanam',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showSeasonForm(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Musim',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
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
          ),

          const SizedBox(height: 24),

          // ── Summary Stat Cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.calendar_month_outlined,
                  label: 'Total Musim',
                  value: '$totalMusim',
                  iconColor: AppTheme.green700,
                  iconBg: AppTheme.green100,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  icon: Icons.eco_outlined,
                  label: 'Musim Aktif',
                  value: '$musimAktif',
                  iconColor: AppTheme.green700,
                  iconBg: AppTheme.green100,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  icon: Icons.event_available_outlined,
                  label: 'Musim Selesai',
                  value: '$musimSelesai',
                  iconColor: AppTheme.green700,
                  iconBg: AppTheme.green100,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Table Card
          if (_seasons.isEmpty)
            Container(
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: _buildEmptyState(),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: const Color(0xFFF9FAFB),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: const Row(
                      children: [
                        _ColHeader(text: 'NO', flex: 1),
                        _ColHeader(text: 'NAMA MUSIM', flex: 3),
                        _ColHeader(text: 'TANGGAL MULAI', flex: 2),
                        _ColHeader(text: 'TANGGAL SELESAI', flex: 2),
                        _ColHeader(text: 'STATUS', flex: 2),
                        _ColHeader(text: 'TOTAL PANEN', flex: 2),
                        _ColHeader(text: 'AKSI', flex: 2),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  ...List.generate(_seasons.length, (index) {
                    final season = _seasons[index];
                    final isLast = index == _seasons.length - 1;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  season.name,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _formatDateString(season.startDate),
                                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _formatDateString(season.endDate),
                                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: _buildStatusBadge(season.status),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${_formatNumber(season.totalPanen)} kg',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.green700,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _ActionBtn(
                                      icon: Icons.edit_outlined,
                                      color: AppTheme.blue600,
                                      bgColor: AppTheme.blue100,
                                      tooltip: 'Edit',
                                      onTap: () => _showSeasonForm(season: season),
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionBtn(
                                      icon: Icons.delete_outline,
                                      color: AppTheme.red600,
                                      bgColor: AppTheme.red100,
                                      tooltip: 'Hapus',
                                      onTap: () => _deleteSeason(season),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isLast) const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      ],
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'active':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF166534);
        label = 'Aktif';
        break;
      case 'completed':
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF1E40AF);
        label = 'Selesai';
        break;
      default:
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        label = status;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _formatDateString(String dateStr) {
    if (dateStr.isEmpty) return '-';
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy', 'id').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatNumber(double value) {
    if (value == 0) return '0';
    final formatter = NumberFormat('#,##0', 'id');
    return formatter.format(value);
  }
}

// ── Reusable helper widgets ──────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color iconBg;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        height: 1.1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String text;
  final int flex;

  const _ColHeader({required this.text, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

class _SeasonFormBottomSheet extends StatefulWidget {
  final ApiService apiService;
  final Season? season;
  final List<Season> existingSeasons;
  final Function(Season) onSuccess;

  const _SeasonFormBottomSheet({
    required this.apiService,
    this.season,
    required this.existingSeasons,
    required this.onSuccess,
  });

  @override
  State<_SeasonFormBottomSheet> createState() => _SeasonFormBottomSheetState();
}

class _SeasonFormBottomSheetState extends State<_SeasonFormBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late TextEditingController _targetKgController;
  late TextEditingController _notesController;
  String _status = 'active';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.season?.name ?? '');
    _startDateController = TextEditingController(text: widget.season?.startDate ?? '');
    _endDateController = TextEditingController(text: widget.season?.endDate ?? '');
    _notesController = TextEditingController(text: widget.season?.notes ?? '');
    _targetKgController = TextEditingController(text: widget.season != null ? widget.season!.targetKg.toString() : '');
    _status = widget.season?.status ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _targetKgController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('id', 'ID'),
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toString().split(' ')[0];
      });
    }
  }

  Future<void> _submitForm() async {
    if (_nameController.text.isEmpty ||
        _startDateController.text.isEmpty ||
        _endDateController.text.isEmpty ||
        _targetKgController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    final normalizedName = _nameController.text.trim().toLowerCase();
    final hasDuplicateName = widget.existingSeasons.any((season) {
      final seasonName = season.name.trim().toLowerCase();
      return seasonName == normalizedName && (widget.season == null || season.id != widget.season!.id);
    });

    if (hasDuplicateName) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama musim tanam sudah digunakan. Gunakan nama lain.')),
      );
      return;
    }

    final startDate = DateTime.tryParse(_startDateController.text);
    final endDate = DateTime.tryParse(_endDateController.text);
    if (startDate == null || endDate == null || endDate.isBefore(startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal akhir harus setelah tanggal mulai.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final targetKg = double.tryParse(_targetKgController.text) ?? 0;

      Map<String, dynamic> result;

      if (widget.season == null) {
        // Create new season
        result = await widget.apiService.createSeason(
          name: _nameController.text,
          startDate: _startDateController.text,
          endDate: _endDateController.text,
          status: _status,
          targetKg: targetKg,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
      } else {
        // Update existing season
        result = await widget.apiService.updateSeason(
          widget.season!.id,
          name: _nameController.text,
          startDate: _startDateController.text,
          endDate: _endDateController.text,
          status: _status,
          targetKg: targetKg,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
      }

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Berhasil disimpan')),
          );
          widget.onSuccess(result['season']);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Gagal disimpan')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration({required String label, Widget? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefixIcon,
      labelStyle: const TextStyle(color: Color(0xFF4A5568)),
      filled: true,
      fillColor: const Color(0xFFFAF9F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.green700, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.season != null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(4.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditMode ? 'Edit Musim Tanam' : 'Tambah Musim Tanam',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B4332),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: _inputDecoration(
                      label: 'Nama Musim Tanam',
                      prefixIcon: const Icon(Icons.calendar_month),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _startDateController,
                    decoration: _inputDecoration(
                      label: 'Tanggal Mulai',
                      prefixIcon: const Icon(Icons.date_range),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(_startDateController),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _endDateController,
                    decoration: _inputDecoration(
                      label: 'Tanggal Selesai',
                      prefixIcon: const Icon(Icons.date_range),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(_endDateController),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _targetKgController,
                    decoration: _inputDecoration(
                      label: 'Target Kg',
                      prefixIcon: const Icon(Icons.scale),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: _inputDecoration(
                      label: 'Status',
                      prefixIcon: const Icon(Icons.info),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Aktif')),
                      DropdownMenuItem(value: 'completed', child: Text('Selesai')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Dibatalkan')),
                    ],
                    onChanged: (value) => setState(() => _status = value ?? 'active'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    decoration: _inputDecoration(
                      label: 'Catatan (Opsional)',
                      prefixIcon: const Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Batal',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                          onPressed: _isLoading ? null : _submitForm,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Simpan',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
