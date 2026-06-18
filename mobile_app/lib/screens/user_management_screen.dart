import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _apiService.getSuperAdminUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Gagal mengambil data user: $e');
    }
  }

  Future<void> _impersonateUser(int id, String name) async {
    final navigator = Navigator.of(context);
    final auth = context.read<AuthProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Impersonasi Akun'),
        content: Text('Apakah Anda ingin masuk dan bertindak sebagai petani "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Masuk Session', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await auth.impersonate(id);
      if (success) {
        _showSuccess('Impersonasi aktif! Bertindak sebagai $name');
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        setState(() => _isLoading = false);
        _showError('Gagal melakukan impersonasi');
      }
    }
  }

  Future<void> _deleteUser(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Akun'),
        content: Text('Apakah Anda yakin ingin menghapus akun "$name" secara permanen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus Permanen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final result = await _apiService.deleteSuperAdminUser(id);
      if (result['success'] == true) {
        _showSuccess('Akun berhasil dihapus permanen');
        _loadUsers();
      } else {
        setState(() => _isLoading = false);
        _showError(result['message'] ?? 'Gagal menghapus akun');
      }
    }
  }

  void _showAddEditUserBottomSheet([Map<String, dynamic>? user]) {
    final isEdit = user != null;
    final nameController = TextEditingController(text: user?['name'] ?? '');
    final emailController = TextEditingController(text: user?['email'] ?? '');
    final phoneController = TextEditingController(text: user?['phone'] ?? '');
    final farmNameController = TextEditingController(text: user?['farm_name'] ?? '');
    final passwordController = TextEditingController();
    
    String role = user?['role'] ?? 'user';
    String status = user?['status'] ?? 'active';
    
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24, left: 24, right: 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Ubah Akun Petani' : 'Registrasi Akun Baru',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                  validator: (val) => val == null || val.isEmpty ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) => val == null || val.isEmpty ? 'Email wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                if (!isEdit)
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (val) => val == null || val.isEmpty ? 'Password wajib diisi' : null,
                  ),
                if (!isEdit) const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                  keyboardType: TextInputType.phone,
                  validator: (val) => val == null || val.isEmpty ? 'Nomor telepon wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: farmNameController,
                  decoration: const InputDecoration(labelText: 'Nama Kelompok Tani / Lahan'),
                  validator: (val) => val == null || val.isEmpty ? 'Nama lahan wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                
                // Dropdowns for Role, Status, and Approval
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: role,
                        decoration: const InputDecoration(labelText: 'Hak Akses'),
                        items: const [
                          DropdownMenuItem(value: 'user', child: Text('Petani')),
                          DropdownMenuItem(value: 'super_admin', child: Text('Admin')),
                        ],
                        onChanged: (val) => role = val!,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text('Aktif')),
                          DropdownMenuItem(value: 'inactive', child: Text('Non-aktif')),
                        ],
                        onChanged: (val) => status = val!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF135835),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.pop(context);
                      setState(() => _isLoading = true);

                      final dataMap = {
                        'name': nameController.text.trim(),
                        'email': emailController.text.trim(),
                        'phone': phoneController.text.trim(),
                        'farm_name': farmNameController.text.trim(),
                        'role': role,
                        'status': status,
                      };
                      if (!isEdit) {
                        dataMap['password'] = passwordController.text;
                      }

                      final Map<String, dynamic> res;
                      if (isEdit) {
                        res = await _apiService.updateSuperAdminUser(user['id'] as int, dataMap);
                      } else {
                        res = await _apiService.createSuperAdminUser(dataMap);
                      }

                      if (res['success'] == true) {
                        _showSuccess(isEdit ? 'Data akun berhasil diperbarui' : 'Akun baru berhasil diregistrasikan');
                        _loadUsers();
                      } else {
                        setState(() => _isLoading = false);
                        _showError(res['message'] ?? 'Gagal memproses akun');
                      }
                    },
                    child: Text(isEdit ? 'Perbarui Akun' : 'Daftarkan Akun'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  List<dynamic> _getFilteredUsers(int index) {
    if (index == 0) return _users;
    return _users.where((u) => u['status'] == 'active').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Akun Tani'),
        backgroundColor: const Color(0xFF135835),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: () => _showAddEditUserBottomSheet(),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Aktif'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF135835)))
          : TabBarView(
              controller: _tabController,
              children: List.generate(2, (index) {
                final filteredList = _getFilteredUsers(index);
                if (filteredList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Tidak ada data akun dalam kategori ini', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 800) {
                      return _buildDesktopLayout(filteredList);
                    }
                    return _buildMobileLayout(filteredList);
                  },
                );
              }),
            ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = status == 'active' ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status == 'active' ? 'AKTIF' : 'NON-AKTIF',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> u) {
    final isAdmin = u['role'] == 'super_admin';
    final id = u['id'] as int;
    final name = u['name'] ?? '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!isAdmin && u['status'] == 'active') ...[
          TextButton.icon(
            onPressed: () => _impersonateUser(id, name),
            icon: const Icon(Icons.login, size: 14, color: Colors.blue),
            label: const Text('Impersonasi', style: TextStyle(color: Colors.blue, fontSize: 12)),
          ),
          const SizedBox(width: 4),
        ],
        TextButton.icon(
          onPressed: () => _showAddEditUserBottomSheet(u),
          icon: const Icon(Icons.edit, size: 14, color: Colors.black54),
          label: const Text('Ubah', style: TextStyle(color: Colors.black87, fontSize: 12)),
        ),
        const SizedBox(width: 4),
        TextButton.icon(
          onPressed: () => _deleteUser(id, name),
          icon: const Icon(Icons.delete, size: 14, color: Colors.red),
          label: const Text('Hapus', style: TextStyle(color: Colors.red, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(List<dynamic> filteredList) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredList.length,
      separatorBuilder: (context, idx) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final u = filteredList[idx];
        final isAdmin = u['role'] == 'super_admin';
        
        return Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: (isAdmin ? Colors.amber : const Color(0xFF1A7A4A)).withValues(alpha: 0.1),
                      child: Icon(
                        isAdmin ? Icons.admin_panel_settings : Icons.person,
                        color: isAdmin ? Colors.amber.shade800 : const Color(0xFF1A7A4A),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(u['email'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          if (u['farm_name'] != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.landscape_rounded, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(u['farm_name'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black54)),
                              ],
                            ),
                          ]
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildStatusBadge(u['status']),
                        const SizedBox(height: 6),
                        _buildStatusBadge(u['status']),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildActionButtons(u as Map<String, dynamic>),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout(List<dynamic> filteredList) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
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
                    const Text('Daftar Akun Tani', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                    Text('Total: ${filteredList.length} Akun', style: const TextStyle(color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              const Divider(height: 1),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 80),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.resolveWith<Color>((states) => const Color(0xFFF9FAFB)),
                    dataRowMaxHeight: 70,
                    columns: const [
                      DataColumn(label: Text('Nama & Email', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Nama Lahan', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Nomor Telepon', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Hak Akses', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Persetujuan', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: filteredList.map((u) {
                      final isAdmin = u['role'] == 'super_admin';
                      return DataRow(
                        cells: [
                          DataCell(Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(u['email'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          )),
                          DataCell(Text(u['farm_name'] ?? '-')),
                          DataCell(Text(u['phone'] ?? '-')),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isAdmin ? Colors.amber : const Color(0xFF1A7A4A)).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isAdmin ? 'Admin' : 'Petani',
                              style: TextStyle(
                                color: isAdmin ? Colors.amber.shade900 : const Color(0xFF1A7A4A),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          )),
                          DataCell(_buildStatusBadge(u['status'])),
                          DataCell(_buildStatusBadge(u['status'])),
                          DataCell(_buildActionButtons(u as Map<String, dynamic>)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
