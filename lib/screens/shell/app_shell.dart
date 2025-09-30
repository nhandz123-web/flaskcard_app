import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flashcard_app/l10n/app_localizations.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    print('AppShell locale: ${l10n.localeName}'); // Debug locale
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: l10n.home),
          NavigationDestination(
              icon: const Icon(Icons.collections_bookmark_outlined),
              selectedIcon: const Icon(Icons.collections_bookmark),
              label: l10n.deck),
          NavigationDestination(
              icon: const Icon(Icons.school_outlined),
              selectedIcon: const Icon(Icons.school),
              label: l10n.learn),
          NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: l10n.profile),
        ],
      ),
      appBar: _buildAppBar(context),
    );
  }

  PreferredSizeWidget? _buildAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = navigationShell.currentIndex;
    if (currentIndex != 3) return null;
    if (location == '/app/profile/settings') {
      return AppBar(
        title: Text(l10n.settings_title),
      );
    }
    return AppBar(
      title: Text(l10n.profile),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            context.push('/app/profile/settings');
          },
          tooltip: l10n.settings_title,
        ),
      ],
    );
  }
}