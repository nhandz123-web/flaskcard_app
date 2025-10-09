import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flashcard_app/services/api_service.dart';
import 'package:flashcard_app/providers/user_provider.dart';
import 'package:flashcard_app/models/deck.dart';
import 'package:flashcard_app/core/settings/settings_provider.dart';
import 'package:flashcard_app/l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  final ApiService api;
  const HomePage({super.key, required this.api});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Deck> decks = [];
  bool isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  Future<void> _loadDecks() async {
    setState(() => isLoading = true);
    try {
      final fetchedDecks = await widget.api.getDecks();
      setState(() {
        decks = fetchedDecks;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.errorLoadingDecks ?? 'Error loading decks'}: $e')),
      );
    }
  }

  void _navigateToLearn(BuildContext context) {
    context.go('/app/learn'); // Navigate to LearnPage
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 2) {
      _navigateToLearn(context); // Navigate to LearnPage
    } else if (index == 1) {
      context.go('/app/decks', extra: widget.api);
    } else if (index == 3) {
      context.go('/app/profile');
    } else if (index == 0) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, SettingsProvider>(
      builder: (context, userProvider, settings, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          body: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: settings.fontScale,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    width: double.infinity,
                    color: Colors.red,
                    child: Text(
                      AppLocalizations.of(context)!.lexiFlash ?? 'LexiFlash',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      ),
                      const SizedBox(height: 10),
                      Text.rich(
                        TextSpan(
                          text: "${AppLocalizations.of(context)!.welcome ?? 'Welcome'} ",
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          children: [
                            TextSpan(
                              text: userProvider.name ?? 'User',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(text: " ${AppLocalizations.of(context)!.welcomeBack ?? 'back'}!"),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isLoading
                              ? AppLocalizations.of(context)!.loading ?? 'Loading...'
                              : decks.isEmpty
                              ? AppLocalizations.of(context)!.noDecks ?? 'No decks available'
                              : "${AppLocalizations.of(context)!.dueCards ?? 'Cards due today'}\n${decks.fold(0, (sum, deck) => sum + deck.cardsCount)} ${AppLocalizations.of(context)!.cards ?? 'cards'} - ${AppLocalizations.of(context)!.goal ?? 'goal'}: 20 ${AppLocalizations.of(context)!.cardsPerDay ?? 'cards/day'}",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: Colors.red.withOpacity(0.6),
                      ),
                      onPressed: isLoading ? null : () => _navigateToLearn(context),
                      child: Text(
                        AppLocalizations.of(context)!.learnNow ?? 'Learn Now',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${AppLocalizations.of(context)!.streak ?? 'Streak'}: 7 ${AppLocalizations.of(context)!.days ?? 'days'}",
                          style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Icon(
                          Icons.check_box,
                          color: Theme.of(context).colorScheme.secondary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).bottomAppBarTheme.color,
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomNavItem(
                  icon: Icons.home,
                  label: AppLocalizations.of(context)!.home ?? 'Home',
                  active: _selectedIndex == 0,
                  onTap: () => _onItemTapped(0),
                  context: context,
                ),
                _BottomNavItem(
                  icon: Icons.library_books,
                  label: AppLocalizations.of(context)!.deck ?? 'Deck',
                  active: _selectedIndex == 1,
                  onTap: () => _onItemTapped(1),
                  context: context,
                ),
                _BottomNavItem(
                  icon: Icons.school,
                  label: AppLocalizations.of(context)!.learn ?? 'Learn',
                  active: _selectedIndex == 2,
                  onTap: () => _onItemTapped(2),
                  context: context,
                ),
                _BottomNavItem(
                  icon: Icons.account_circle,
                  label: AppLocalizations.of(context)!.profile ?? 'Profile',
                  active: _selectedIndex == 3,
                  onTap: () => _onItemTapped(3),
                  context: context,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final BuildContext context;

  const _BottomNavItem({
    required this.icon,
    this.label = "",
    this.active = false,
    this.onTap,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = Theme.of(context).iconTheme.size ?? 24;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              size: iconSize,
            ),
            if (label.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  label,
                  style: TextStyle(
                    color: active
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}