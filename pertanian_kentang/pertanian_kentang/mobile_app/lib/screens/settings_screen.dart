import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_theme.dart';
import '../login_screen.dart';
import 'home_screen.dart';
import 'season_screen.dart';
import 'harvest_screen.dart';
import 'stock_screen.dart';
import 'sales_screen.dart';
import 'costs_screen.dart';
import 'reports_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  bool _isSavingProfile = false;
  bool _isDeletingAccount = false;
  bool _isSavingPassword = false;
  bool _isSavingGudang = false;
  bool _isSavingNotif = false;
  bool _isSendingFeedback = false;

  // Profile forms
  final _profileFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _farmNameController = TextEditingController();

  // Password forms
  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Gudang forms
  final _gudangFormKey = GlobalKey<FormState>();
  final _minStockController = TextEditingController();
  final _maxStockController = TextEditingController();

  // Notifications toggles
  bool _notifyLowStock = true;
  bool _notifyNewSale = true;
  bool _notifyCost = true;

  // Feedback form
  final _feedbackFormKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _farmNameController.dispose();

    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    _minStockController.dispose();
    _maxStockController.dispose();

    _feedbackController.dispose();
    super.dispose();
  }

  
  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Akun'),
        content: const Text('Apakah Anda yakin ingin menghapus akun ini secara permanen? Semua data Anda akan terhapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeletingAccount = true);
    final result = await _apiService.deleteAccount();
    setState(() => _isDeletingAccount = false);

    if (result['success'] == true) {
      _showSuccess(result['message'] ?? 'Akun berhasil dihapus');
      if (mounted) {
        await Provider.of<AuthProvider>(context, listen: false).logout();
      }
    } else {
      _showError(result['message'] ?? 'Gagal menghapus akun');
    }
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getSettings();
      if (data != null) {
        final u = data['user'] ?? {};
        _nameController.text = u['name'] ?? '';
        _emailController.text = u['email'] ?? '';
        _phoneController.text = u['phone'] ?? '';
        _farmNameController.text = u['farm_name'] ?? '';

        _minStockController.text = (data['min_stock'] ?? 100).toString();
        _maxStockController.text = (data['max_stock'] ?? 5000).toString();

        _notifyLowStock = data['notify_low_stock'] as bool? ?? true;
        _notifyNewSale = data['notify_new_sale'] as bool? ?? true;
        _notifyCost = data['notify_cost'] as bool? ?? true;
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Gagal mengambil pengaturan: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSavingProfile = true);

    final result = await _apiService.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      farmName: _farmNameController.text.trim(),
    );

    setState(() => _isSavingProfile = false);
    if (result['success'] == true) {
      _showSuccess(result['message'] ?? 'Profil berhasil diperbarui');
      _loadSettings();
    } else {
      _showError(result['message'] ?? 'Gagal memperbarui profil');
    }
  }

  Future<void> _savePassword() async {
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSavingPassword = true);

    final result = await _apiService.updatePassword(
      currentPassword: _currentPasswordController.text,
      password: _newPasswordController.text,
      passwordConfirmation: _confirmPasswordController.text,
    );

    setState(() => _isSavingPassword = false);
    if (result['success'] == true) {
      _showSuccess(result['message'] ?? 'Password berhasil diperbarui');
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } else {
      _showError(result['message'] ?? 'Gagal memperbarui password');
    }
  }

  Future<void> _saveGudang() async {
    if (!_gudangFormKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSavingGudang = true);

    final min = int.tryParse(_minStockController.text) ?? 100;
    final max = int.tryParse(_maxStockController.text) ?? 5000;

    final result = await _apiService.updateWarehouseThresholds(
      minStock: min,
      maxStock: max,
    );

    setState(() => _isSavingGudang = false);
    if (result['success'] == true) {
      _showSuccess(result['message'] ?? 'Ambang batas gudang diperbarui');
    } else {
      _showError(result['message'] ?? 'Gagal memperbarui ambang batas');
    }
  }

  Future<void> _saveNotifications() async {
    setState(() => _isSavingNotif = true);

    final result = await _apiService.updateNotifications(
      notifyLowStock: _notifyLowStock,
      notifyNewSale: _notifyNewSale,
      notifyCost: _notifyCost,
    );

    setState(() => _isSavingNotif = false);
    if (result['success'] == true) {
      _showSuccess(result['message'] ?? 'Konfigurasi notifikasi disimpan');
    } else {
      _showError(result['message'] ?? 'Gagal menyimpan notifikasi');
    }
  }

  Future<void> _sendFeedback() async {
    FocusScope.of(context).unfocus();
    if (!_feedbackFormKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSendingFeedback = true);

    final result = await _apiService.sendFeedback(
      _feedbackController.text.trim(),
    );

    setState(() => _isSendingFeedback = false);
    if (result['success'] == true) {
      _showSuccess('Saran Anda berhasil dikirim ke Admin kelompok tani!');
      _feedbackController.clear();
    } else {
      _showError(result['message'] ?? 'Gagal mengirim saran');
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                  title: 'Pengaturan',
                  userInitials: initials,
                  onNotificationTap: _loadSettings,
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
                        title: 'Pengaturan',
                        subtitle: 'Atur profil, keamanan, dan notifikasi',
                        userInitials: initials,
                        onRefresh: _loadSettings,
                      ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppTheme.green700))
                          : SingleChildScrollView(
                              padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
                              child: Center(
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth: isDesktop ? 1200 : 700,
                                  ),
                                  child: isDesktop
                                      ? Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                children: [
                                                  _buildProfileCard(),
                                                  const SizedBox(height: 20),
                                                  _buildPasswordCard(),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 24),
                                            Expanded(
                                              child: Column(
                                                children: [
                                                  _buildGudangCard(),
                                                  const SizedBox(height: 20),
                                                  _buildNotificationCard(),
                                                  const SizedBox(height: 20),
                                                  _buildFeedbackCard(),
                                                ],
                                              ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          children: [
                                            _buildProfileCard(),
                                            const SizedBox(height: 16),
                                            _buildPasswordCard(),
                                            const SizedBox(height: 16),
                                            _buildGudangCard(),
                                            const SizedBox(height: 16),
                                            _buildNotificationCard(),
                                            const SizedBox(height: 16),
                                            _buildFeedbackCard(),
                                            const SizedBox(height: 24),
                                          ],
                                        ),
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

  Widget _buildProfileCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _profileFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                Icons.person_outline,
                'Profil Pengguna',
                const Color(0xFF27AE60),
              ),
              const Divider(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Nama tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Alamat Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value == null || value.isEmpty
                    ? 'Email tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'No. Telepon'),
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.isEmpty
                    ? 'Nomor telepon tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _farmNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Kelompok Tani / Lahan',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isSavingProfile ? null : _saveProfile,
                  child: _isSavingProfile
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Simpan Profil'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isDeletingAccount ? null : _deleteAccount,
                  child: _isDeletingAccount
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.red,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Hapus Akun Permanen'),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _passwordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                Icons.lock_outline,
                'Keamanan (Ubah Password)',
                Colors.blue,
              ),
              const Divider(height: 24),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Password Saat Ini',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Password lama wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password baru wajib diisi';
                  }
                  if (value.length < 6) {
                    return 'Password minimal 6 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'Konfirmasi password tidak cocok';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isSavingPassword ? null : _savePassword,
                  child: _isSavingPassword
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Ubah Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGudangCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _gudangFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                Icons.warehouse_outlined,
                'Ambang Batas Gudang',
                Colors.orange,
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minStockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Batas Stok Min (kg)',
                      ),
                      validator: (value) =>
                          value == null || int.tryParse(value) == null
                          ? 'Wajib diisi'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxStockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Batas Stok Maks (kg)',
                      ),
                      validator: (value) =>
                          value == null || int.tryParse(value) == null
                          ? 'Wajib diisi'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isSavingGudang ? null : _saveGudang,
                  child: _isSavingGudang
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Perbarui Ambang Batas'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              Icons.notifications_active_outlined,
              'Preferensi Notifikasi',
              Colors.purple,
            ),
            const Divider(height: 24),
            SwitchListTile(
              title: const Text(
                'Batas Stok Rendah',
                style: TextStyle(fontSize: 14),
              ),
              subtitle: const Text(
                'Notifikasi jika persediaan di gudang mendekati minimal',
                style: TextStyle(fontSize: 11),
              ),
              value: _notifyLowStock,
              activeThumbColor: Colors.purple,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _notifyLowStock = val),
            ),
            SwitchListTile(
              title: const Text(
                'Penjualan Baru',
                style: TextStyle(fontSize: 14),
              ),
              subtitle: const Text(
                'Notifikasi tiap kali ada penjualan kentang yang tercatat',
                style: TextStyle(fontSize: 11),
              ),
              value: _notifyNewSale,
              activeThumbColor: Colors.purple,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _notifyNewSale = val),
            ),
            SwitchListTile(
              title: const Text(
                'Biaya Lahan Baru',
                style: TextStyle(fontSize: 14),
              ),
              subtitle: const Text(
                'Notifikasi pengingat pengeluaran baru kelompok tani',
                style: TextStyle(fontSize: 11),
              ),
              value: _notifyCost,
              activeThumbColor: Colors.purple,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _notifyCost = val),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isSavingNotif ? null : _saveNotifications,
                child: _isSavingNotif
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Simpan Preferensi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _feedbackFormKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                Icons.feedback_outlined,
                'Kirim Masukan & Saran',
                Colors.teal,
              ),
              const Divider(height: 24),
              TextFormField(
                controller: _feedbackController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      'Tulis kritik, saran, masukan, atau kendala Anda di sini...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Masukan tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isSendingFeedback ? null : _sendFeedback,
                  child: _isSendingFeedback
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Kirim Masukan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
