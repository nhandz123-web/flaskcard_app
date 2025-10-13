import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flashcard_app/l10n/app_localizations.dart'; // Import AppLocalizations

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Lấy chuỗi dịch

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: l10n.home ?? 'Trang chủ', // Chuỗi dịch với fallback
                  isActive: navigationShell.currentIndex == 0,
                  onTap: () => context.go('/app/home'),
                ),
                _NavItem(
                  icon: Icons.auto_stories_rounded,
                  label: l10n.deck ?? 'Bộ thẻ', // Chuỗi dịch với fallback
                  isActive: navigationShell.currentIndex == 1,
                  onTap: () => context.go('/app/decks'),
                ),
                _NavItem(
                  icon: Icons.school_rounded,
                  label: l10n.learn ?? 'Học tập', // Chuỗi dịch với fallback
                  isActive: navigationShell.currentIndex == 2,
                  onTap: () => context.go('/app/learn'),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: l10n.profile ?? 'Hồ sơ', // Chuỗi dịch với fallback
                  isActive: navigationShell.currentIndex == 3,
                  onTap: () => context.go('/app/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.red.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 26,
                    color: isActive
                        ? Colors.red
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // Style giống HomePage
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? Colors.red
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // Style giống HomePage
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}