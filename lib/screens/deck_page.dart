import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/deck.dart' as deck_model;
import '../core/settings/settings_provider.dart';
import '../l10n/app_localizations.dart';
import 'add_cards_page.dart'; // Import màn hình mới

class DeckPage extends StatefulWidget {
  final ApiService api;

  const DeckPage({super.key, required this.api});

  @override
  State<DeckPage> createState() => _DeckPageState();
}

class _DeckPageState extends State<DeckPage> {
  late Future<List<deck_model.Deck>> _decksFuture;

  @override
  void initState() {
    super.initState();
    _refreshDecks();
  }

  void _refreshDecks() {
    print('Refreshing decks');
    setState(() {
      _decksFuture = widget.api.getDecks();
    });
  }

  @override
  void didUpdateWidget(covariant DeckPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.api != widget.api) {
      _refreshDecks();
    }
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
                    child: FutureBuilder<List<deck_model.Deck>>(
                      future: _decksFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              '${AppLocalizations.of(context)!.errorLoadingDecks ?? 'Error'}: ${snapshot.error}',
                              style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Text(
                              AppLocalizations.of(context)!.noDecks ?? 'No decks available',
                              style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                            ),
                          );
                        }

                        final decks = snapshot.data!;
                        return Container(
                          color: Theme.of(context).colorScheme.surface,
                          padding: const EdgeInsets.all(12),
                          child: ListView.builder(
                            itemCount: decks.length,
                            itemBuilder: (context, index) {
                              final deck = decks[index];
                              return GestureDetector(
                                onTap: () {
                                  context.go('/app/deck/${deck.id}/cards');
                                },
                                child: Card(
                                  color: Theme.of(context).cardColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white.withOpacity(0.2)
                                          : Colors.grey.withOpacity(0.3),
                                      width: 1.0,
                                    ),
                                  ),
                                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                deck.name,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: Theme.of(context).colorScheme.onSurface,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                deck.description,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${AppLocalizations.of(context)!.cards ?? 'Cards'}: ${deck.cardsCount}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${AppLocalizations.of(context)!.createdDate ?? 'Created'}: ${deck.createdAt.toLocal().toString().split(' ')[0]}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert, size: 30, color: Colors.grey),
                                          onSelected: (value) async {
                                            switch (value) {
                                              case 'delete':
                                                await _handleDeleteDeck(context, deck.id);
                                                break;
                                              case 'edit':
                                                await _handleEditDeck(context, deck.id);
                                                break;
                                              case 'add_cards':
                                                await _handleAddCards(context, deck.id);
                                                break;
                                            }
                                          },
                                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                            PopupMenuItem<String>(
                                              value: 'delete',
                                              child: ListTile(
                                                leading: const Icon(Icons.delete, size: 30),
                                                title: Text(AppLocalizations.of(context)!.delete ?? 'Delete'),
                                              ),
                                            ),
                                            PopupMenuItem<String>(
                                              value: 'edit',
                                              child: ListTile(
                                                leading: const Icon(Icons.edit, size: 30),
                                                title: Text(AppLocalizations.of(context)!.edit ?? 'Edit'),
                                              ),
                                            ),
                                            PopupMenuItem<String>(
                                              value: 'add_cards',
                                              child: ListTile(
                                                leading: const Icon(Icons.add_card, size: 30),
                                                title: Text(AppLocalizations.of(context)!.addCards ?? 'Add Cards'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
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
          floatingActionButton: FloatingActionButton(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onPressed: () {
              context.go('/app/create-deck');
            },
            child: const Icon(Icons.add, size: 32),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).bottomAppBarTheme.color,
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomNavItem(
                  icon: Icons.home,
                  label: AppLocalizations.of(context)!.home ?? 'Home',
                  active: false,
                  onTap: () => context.go('/home'),
                  context: context,
                ),
                _BottomNavItem(
                  icon: Icons.library_books,
                  label: AppLocalizations.of(context)!.deck ?? 'Deck',
                  active: true,
                  onTap: () => context.go('/app/decks'),
                  context: context,
                ),
                _BottomNavItem(
                  icon: Icons.school,
                  label: AppLocalizations.of(context)!.learn ?? 'Learn',
                  active: false,
                  onTap: () => context.go('/app/learn'),
                  context: context,
                ),
                _BottomNavItem(
                  icon: Icons.account_circle,
                  label: AppLocalizations.of(context)!.profile ?? 'Profile',
                  active: false,
                  onTap: () => context.go('/app/profile'),
                  context: context,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleDeleteDeck(BuildContext context, int deckId) async {
    try {
      await context.read<ApiService>().deleteDeck(deckId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.deckDeletedSuccessfully ?? 'Deck deleted successfully')),
      );
      _refreshDecks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.errorDeletingDeck ?? 'Error'}: $e')),
      );
    }
  }

  Future<void> _handleEditDeck(BuildContext context, int deckId) async {
    try {
      final deck = await context.read<ApiService>().getDeck(deckId);
      context.go('/app/edit-deck/$deckId');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.errorLoadingDeck ?? 'Error'}: $e')),
      );
    }
  }

  Future<void> _handleAddCards(BuildContext context, int deckId) async {
    final result = await context.push('/app/deck/$deckId/add-cards', extra: {'api': widget.api});
    if (result == true && mounted) {
      print('Refreshing decks after adding cards');
      _refreshDecks();
    }
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