import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/deck.dart' as deck_model;
import '../core/settings/settings_provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/deck_provider.dart';

class LearnPage extends StatefulWidget {
  final ApiService api;

  const LearnPage({super.key, required this.api});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    print('Khởi tạo LearnPage');
    WidgetsBinding.instance.addObserver(this);
    _refreshDecks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      print('LearnPage hiển thị lại');
      _refreshDecks();
    }
  }

  void _refreshDecks() {
    print('Refreshing decks for LearnPage');
    widget.api.refreshDecks();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
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
                  Expanded(
                    child: Consumer<DeckProvider>(
                      builder: (context, deckProvider, child) {
                        print('DeckProvider state: loading=${deckProvider.isLoading}, decks=${deckProvider.decks.length}, error=${deckProvider.error}');
                        if (deckProvider.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (deckProvider.error != null) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${AppLocalizations.of(context)!.errorLoadingDecks ?? 'Error'}: ${deckProvider.error}',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _refreshDecks,
                                  child: Text(AppLocalizations.of(context)!.retry ?? 'Retry'),
                                ),
                              ],
                            ),
                          );
                        }
                        if (deckProvider.decks.isEmpty) {
                          return Center(
                            child: Text(
                              AppLocalizations.of(context)!.noDecks ?? 'No decks available',
                              style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                            ),
                          );
                        }

                        final decks = deckProvider.decks;
                        return Container(
                          color: Theme.of(context).colorScheme.surface,
                          padding: const EdgeInsets.all(16),
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.8,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: decks.length,
                            itemBuilder: (context, index) {
                              final deck = decks[index];
                              return Container(
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
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        context.go('/app/learn-deck/${deck.id}');
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [Colors.red.shade400, Colors.red.shade600],
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.red.withOpacity(0.3),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.school_rounded,
                                                color: Colors.white,
                                                size: 32,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              deck.name,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.onSurface,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 6),
                                            Expanded(
                                              child: Text(
                                                deck.description,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                                  height: 1.3,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.grey.shade700.withOpacity(0.5)
                                                    : Colors.grey.shade200,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.style_rounded,
                                                    size: 14,
                                                    color: Colors.red.shade600,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${deck.cardsCount} ${AppLocalizations.of(context)!.cards ?? 'cards'}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
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