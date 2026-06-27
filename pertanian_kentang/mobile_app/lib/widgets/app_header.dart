import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'app_theme.dart';
import '../login_screen.dart';
import '../services/api_service.dart';
import '../models/dashboard.dart';

/// Reusable top header for Desktop layout.
/// Shows title, breadcrumb, notification bell, and user avatar.
class AppHeader extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String userInitials;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onRefresh;
  final VoidCallback? onAvatarTap;
  final List<Widget>? actions;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.userInitials,
    this.onNotificationTap,
    this.onRefresh,
    this.onAvatarTap,
    this.actions,
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  Timer? _pollTimer;
  List<Map<String, dynamic>> _notifications = [];
  int _unread = 0;
  final ApiService _api = ApiService();


  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _fetchNotifications());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    try {
      final res = await _api.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = res.map((n) {
            return {
              'icon': _mapIcon(n['type'] as String?),
              'title': n['title'] ?? n['message'] ?? 'Notifikasi',
              'subtitle': n['message'] ?? '',
              'time': n['created_at'] ?? '',
            };
          }).toList();
          _unread = _notifications.length; // simple: count all as unread
        });
      }
    } catch (e) {
      // ignore
    }
  }

  IconData _mapIcon(String? type) {
    switch (type) {
      case 'low_stock': return Icons.inventory_2_outlined;
      case 'new_sale': return Icons.shopping_cart_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('d MMMM yyyy', 'id').format(now);
    return Container(
      height: AppTheme.headerH,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: AppTheme.cardBg,
        border: Border(bottom: BorderSide(color: AppTheme.cardBorder, width: 1)),
      ),
      child: Row(
        children: [
          // Title + date
Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: AppTheme.h2.copyWith(fontSize: 19)),
                Text(
                  widget.subtitle ?? dateStr,
                  style: AppTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Custom actions
          if (widget.actions != null) ...widget.actions!,
          // Refresh
          if (widget.onRefresh != null)
            _HeaderIcon(icon: Icons.refresh_rounded, onTap: widget.onRefresh!, tooltip: 'Refresh'),

          const SizedBox(width: 2),
          // Notification bell (shows popover)
          Stack(
            children: [
              _HeaderIcon(
                icon: Icons.notifications_outlined,
                onTap: () => _showNotifications(context),
                tooltip: 'Notifikasi',
              ),
              if (_unread > 0)
                Positioned(
                  right: 4, top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('$_unread', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
          // Avatar (shows account menu popover)
          GestureDetector(
            onTap: () => _showAccountMenu(context),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.green500, AppTheme.green700],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  widget.userInitials,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.only(right: 20, top: 80),
        backgroundColor: Colors.transparent,
        child: Align(
          alignment: Alignment.topRight,
          child: Container(
            width: 360,
            decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), boxShadow: AppTheme.cardShadow),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Notifikasi', style: AppTheme.h3),
                      TextButton(onPressed: () {
                        setState(() {
                          _unread = 0;
                        });
                        Navigator.pop(ctx);
                      }, child: const Text('Tandai dibaca')),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.cardBorder),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: _notifications.isEmpty
                        ? [Padding(padding: const EdgeInsets.all(12), child: Text('Tidak ada notifikasi', style: AppTheme.bodySmall))]
                        : _notifications.map((n) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _notifRow(n['icon'] as IconData, n['title'] as String, n['subtitle'] as String, n['time'] as String),
                            )).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _notifRow(IconData icon, String title, String subtitle, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: AppTheme.amber100, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppTheme.amber600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTheme.body.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTheme.bodySmall),
              const SizedBox(height: 6),
              Text(time, style: AppTheme.caption),
            ],
          ),
        ),
      ],
    );
  }

  void _showAccountMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.only(right: 20, top: 80),
        backgroundColor: Colors.transparent,
        child: Align(
          alignment: Alignment.topRight,
          child: Container(
            width: 220,
            decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), boxShadow: AppTheme.cardShadow),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Profil Akun'),
                  onTap: () => Navigator.pop(ctx),
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Pengaturan'),
                  onTap: () => Navigator.pop(ctx),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Keluar', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _HeaderIcon({required this.icon, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 21, color: AppTheme.textSecondary),
          ),
        ),
      ),
    );
  }
}

/// Mobile AppBar factory — returns a PreferredSizeWidget.
class AppMobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String userInitials;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;

  const AppMobileAppBar({
    super.key,
    required this.title,
    required this.userInitials,
    this.onNotificationTap,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.cardBg,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black12,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppTheme.textPrimary, size: 22),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Text(title, style: AppTheme.h3),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppTheme.textSecondary, size: 22),
              onPressed: onNotificationTap ?? () {},
            ),
            const Positioned(
              right: 10, top: 10,
              child: SizedBox(
                width: 7, height: 7,
                child: DecoratedBox(decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: onAvatarTap,
            child: CircleAvatar(
              backgroundColor: AppTheme.green700,
              radius: 17,
              child: Text(userInitials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
