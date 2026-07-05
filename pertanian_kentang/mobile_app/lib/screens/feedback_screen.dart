import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_theme.dart';
import '../utils/navigation_helper.dart';
import '../login_screen.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSending = true);
    final message = _messageController.text.trim();
    final result = await _apiService.sendFeedback(message);
    setState(() => _isSending = false);

    if (result['success'] == true) {
      _messageController.clear();
      _showSnackbar('Ulasan berhasil dikirim. Terima kasih!', Colors.green);
    } else {
      _showSnackbar(result['message'] ?? 'Gagal mengirim ulasan.', Colors.red);
    }
  }

  void _showSnackbar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final name = user?.name ?? 'Petani';
    final email = user?.email ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'P';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          backgroundColor: AppTheme.pageBg,
          appBar: isDesktop
              ? null
              : AppMobileAppBar(
                  title: 'Kirim Ulasan',
                  userInitials: initials,
                ),
          drawer: isDesktop
              ? null
              : AppDrawer(
                  userName: name,
                  userEmail: email,
                  userInitials: initials,
                  onLogout: () => _showLogoutDialog(context),
                  navItems: NavigationHelper.buildNavItems(context, 'feedback'),
                  secondaryItems: NavigationHelper.buildSecondaryNavItems(context, 'feedback'),
                ),
          body: Row(
            children: [
              if (isDesktop)
                AppSidebar(
                  userName: name,
                  userEmail: email,
                  userInitials: initials,
                  onLogout: () => _showLogoutDialog(context),
                  navItems: NavigationHelper.buildNavItems(context, 'feedback'),
                  secondaryItems: NavigationHelper.buildSecondaryNavItems(context, 'feedback'),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (isDesktop)
                      AppHeader(
                        title: 'Kirim Ulasan & Masukan',
                        subtitle: 'Berikan umpan balik atau sarankan fitur baru untuk pengembangan aplikasi',
                        userInitials: initials,
                      ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 700),
                            child: Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBg,
                                borderRadius: AppTheme.card,
                                border: Border.all(color: AppTheme.cardBorder),
                                boxShadow: AppTheme.cardShadow,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.feedback_outlined, color: AppTheme.green700, size: 28),
                                        SizedBox(width: 12),
                                        Text('Formulir Masukan Petani', style: AppTheme.h2),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Masukan dan saran Anda sangat membantu kami dalam menyempurnakan platform manajemen pertanian kentang ini.',
                                      style: AppTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 24),
                                    TextFormField(
                                      controller: _messageController,
                                      maxLines: 6,
                                      decoration: InputDecoration(
                                        labelText: 'Ulasan / Saran',
                                        alignLabelWithHint: true,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        hintText: 'Contoh: Saya butuh notifikasi pemupukan dan peringatan cuaca...',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Isi ulasan atau saran terlebih dahulu';
                                        }
                                        if (value.trim().length < 10) {
                                          return 'Tulis minimal 10 karakter agar kami memahami masukan Anda';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.send),
                                        label: _isSending
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                              )
                                            : const Text('Kirim Ulasan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.green700,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: _isSending ? null : _submitFeedback,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
}
