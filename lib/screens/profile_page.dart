import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flashcard_app/l10n/app_localizations.dart';
import 'package:flashcard_app/services/api_service.dart';
import 'package:flashcard_app/core/settings/settings_provider.dart';

class ProfilePage extends StatelessWidget {
  final ApiService api;

  const ProfilePage({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsProvider>(context);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: settings.fontScale),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
            future: api.me(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.red),
                );
              } else if (snapshot.hasError) {
                return Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.error ?? 'Lỗi tải thông tin',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (snapshot.hasData) {
                final userData = snapshot.data!;
                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: Colors.red,
                      child: Text(
                        l10n.lexiFlash ?? 'LexiFlash',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: Theme.of(context).colorScheme.surface,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              // Profile Card
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white.withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.red.shade400, Colors.red.shade600],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: CircleAvatar(
                                        radius: 40,
                                        backgroundColor: Theme.of(context).colorScheme.surface,
                                        backgroundImage: userData['avatar'] != null
                                            ? NetworkImage(userData['avatar'])
                                            : null,
                                        child: userData['avatar'] == null
                                            ? Icon(
                                          Icons.person_rounded,
                                          size: 44,
                                          color: Colors.red.shade400,
                                        )
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userData['name'] ?? l10n.name ?? 'Người dùng',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            userData['email'] ?? l10n.email ?? 'email@example.com',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  l10n.settings ?? 'Cài đặt',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Menu Items
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white.withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _buildMenuItem(
                                      context: context,
                                      icon: Icons.person_outline_rounded,
                                      iconColor: Colors.blue.shade600,
                                      label: l10n.accountDetails ?? 'Thông tin tài khoản',
                                      onTap: () => context.go('/app/profile/account-details'),
                                      isFirst: true,
                                    ),
                                    _buildDivider(context),
                                    _buildMenuItem(
                                      context: context,
                                      icon: Icons.bar_chart_rounded,
                                      iconColor: Colors.purple.shade600,
                                      label: l10n.statistics ?? 'Thống kê',
                                      onTap: () => context.go('/app/profile/statistics'),
                                    ),
                                    _buildDivider(context),
                                    _buildMenuItem(
                                      context: context,
                                      icon: Icons.settings_rounded,
                                      iconColor: Colors.grey.shade600,
                                      label: l10n.settings ?? 'Cài đặt',
                                      onTap: () => context.go('/app/profile/settings'),
                                    ),
                                    _buildDivider(context),
                                    _buildMenuItem(
                                      context: context,
                                      icon: Icons.help_outline_rounded,
                                      iconColor: Colors.orange.shade600,
                                      label: l10n.help ?? 'Trợ giúp',
                                      onTap: () => context.go('/app/profile/help'),
                                      isLast: true,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Logout Button
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white.withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: _buildMenuItem(
                                  context: context,
                                  icon: Icons.logout_rounded,
                                  iconColor: Colors.red.shade600,
                                  label: l10n.logout ?? 'Đăng xuất',
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        title: Text(l10n.logout ?? 'Đăng xuất'),
                                        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('Hủy'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                                            child: Text(l10n.logout ?? 'Đăng xuất'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      try {
                                        await api.logout();
                                        if (context.mounted) {
                                          context.go('/login');
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('${l10n.error ?? 'Lỗi'}: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  isFirst: true,
                                  isLast: true,
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return Container(
                color: Theme.of(context).colorScheme.surface,
                child: Center(
                  child: Text(
                    l10n.noDeckData ?? 'Không có dữ liệu',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(14) : Radius.zero,
          bottom: isLast ? const Radius.circular(14) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.1)
            : Colors.grey.withOpacity(0.2),
      ),
    );
  }
}