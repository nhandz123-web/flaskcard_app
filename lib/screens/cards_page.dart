import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../models/card.dart' as card_model;
import '../models/deck.dart' as deck_model;
import '../providers/user_provider.dart';
import '../l10n/app_localizations.dart';
import '../core/settings/settings_provider.dart';

class CardsPage extends StatefulWidget {
  final ApiService api;
  final int deckId;
  final deck_model.Deck? deck;

  const CardsPage({super.key, required this.api, required this.deckId, this.deck});

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  late Future<List<card_model.Card>> _cardsFuture;
  late Future<deck_model.Deck> _deckFuture;
  bool _isOwner = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _refreshCards();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.loadUser();
    _deckFuture = _fetchDeck();
    print('InitState - Deck ID: ${widget.deckId}, User ID: ${userProvider.userId}');
  }

  Future<deck_model.Deck> _fetchDeck() async {
    try {
      final deck = await widget.api.getDeck(widget.deckId);
      if (mounted) {
        _updateOwnerStatus(deck);
      }
      print('Fetched Deck - ID: ${deck.id}, User ID: ${deck.userId}, _isOwner: $_isOwner');
      return deck;
    } catch (e) {
      print('Error fetching deck: $e');
      rethrow;
    }
  }

  void _refreshCards() {
    print('Refreshing cards and deck for deckId: ${widget.deckId}');
    if (mounted) {
      setState(() {
        _cardsFuture = widget.api.getCards(widget.deckId);
        _deckFuture = _fetchDeck();
      });
    }
  }

  void _updateOwnerStatus(deck_model.Deck? deck) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (mounted && deck != null) {
      _isOwner = userProvider.userId != null && userProvider.userId == deck.userId;
      print('Updated _isOwner: $_isOwner, User ID: ${userProvider.userId}, Deck User ID: ${deck.userId}');
      if (mounted) setState(() {});
    }
  }

  Future<void> _playAudio(String? audioUrl) async {
    if (audioUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noAudio ?? 'Không có audio')),
      );
      return;
    }

    final fullUrl = 'http://10.12.216.12:8080$audioUrl';
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(fullUrl));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.errorPlayingAudio ?? 'Lỗi phát audio'}: $e')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/app/decks');
        break;
      case 2:
        context.go('/app/learn');
        break;
      case 3:
        context.go('/app/profile');
        break;
    }
  }

  void _editCard(card_model.Card card) async {
    print('Navigating to edit card with ID: ${card.id}');
    final updatedCard = await context.push<card_model.Card>(
      '/app/deck/${widget.deckId}/edit-card/${card.id}',
      extra: {'api': widget.api, 'deckId': widget.deckId, 'card': card},
    );

    if (updatedCard != null && mounted) {
      print('Card updated, refreshing cards for deckId: ${widget.deckId}');
      _refreshCards();
    }
  }

  void _deleteCard(card_model.Card card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirm ?? 'Xác nhận'),
        content: Text(AppLocalizations.of(context)!.confirmDeleteCard ?? 'Bạn có chắc chắn muốn xoá card này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel ?? 'Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.of(context)!.delete ?? 'Xoá'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        print('Attempting to delete card with ID: ${card.id} from deck ID: ${widget.deckId}');
        await widget.api.deleteCard(widget.deckId, card.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.cardDeletedSuccessfully ?? 'Card deleted successfully')),
        );
        _refreshCards();
      } catch (e) {
        final errorMessage = e.toString().isNotEmpty ? e.toString() : 'Unknown error';
        String? localizedError;
        final localizations = AppLocalizations.of(context);
        localizedError = localizations?.errorDeletingCard(errorMessage) ?? 'Error: $errorMessage';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizedError)),
        );
        print('Delete card error: $e');
      }
    }
  }

  void _addCard() async {
    final result = await context.push('/app/deck/${widget.deckId}/add-cards', extra: {'api': widget.api});
    if (result == true && mounted) {
      print('Refreshing after add card...');
      _refreshCards();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('Building CardsPage for deckId: ${widget.deckId}, _isOwner: $_isOwner');
    return WillPopScope(
      onWillPop: () async {
        context.pop();
        return true;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: FutureBuilder<deck_model.Deck>(
          future: _deckFuture,
          builder: (context, deckSnapshot) {
            if (deckSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (deckSnapshot.hasError) {
              return Center(
                child: Text(
                  '${AppLocalizations.of(context)!.errorLoadingDeck ?? 'Error loading deck'}: ${deckSnapshot.error}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                ),
              );
            }

            final deck = deckSnapshot.data ?? widget.deck;
            if (deck == null) {
              return Center(
                child: Text(
                  AppLocalizations.of(context)!.noDeckData ?? 'No deck data',
                  style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                ),
              );
            }

            return Consumer<SettingsProvider>(
              builder: (context, settings, child) {
                return MediaQuery(
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                deck.name.isNotEmpty ? deck.name : (AppLocalizations.of(context)!.lexiFlash ?? 'LexiFlash'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [

                                  Text(
                                    '${AppLocalizations.of(context)!.cards ?? 'Cards'}: ${deck.cardsCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: FutureBuilder<List<card_model.Card>>(
                            future: _cardsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    '${AppLocalizations.of(context)!.errorLoadingCards ?? 'Error loading cards'}: ${snapshot.error}',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                                  ),
                                );
                              }
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return Center(
                                  child: Text(
                                    AppLocalizations.of(context)!.noCards ?? 'Không có card',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                                  ),
                                );
                              }

                              final cards = snapshot.data!;

                              return Container(
                                color: Theme.of(context).colorScheme.surface,
                                padding: const EdgeInsets.all(12),
                                child: ListView.builder(
                                  itemCount: cards.length,
                                  itemBuilder: (context, index) {
                                    final card = cards[index];
                                    final menuKey = GlobalKey();
                                    return GestureDetector(
                                      onTap: () {},
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
                                                      card.front ?? 'No front',
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
                                                      card.back ?? 'No back',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    if (card.createdAt != null)
                                                      Text(
                                                        '${AppLocalizations.of(context)!.createdDate ?? 'Created'}: ${card.createdAt!.toLocal().toString().split(' ')[0]}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (card.imageUrl != null)
                                                    Padding(
                                                      padding: const EdgeInsets.only(right: 8),
                                                      child: Image.network(
                                                        card.imageUrl!,
                                                        width: 30,
                                                        height: 30,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) =>
                                                        const Icon(Icons.broken_image, size: 30),
                                                      ),
                                                    ),
                                                  if (card.audioUrl != null)
                                                    IconButton(
                                                      icon: const Icon(Icons.volume_up),
                                                      iconSize: 30,
                                                      onPressed: () => _playAudio(card.audioUrl),
                                                      color: Theme.of(context).colorScheme.primary,
                                                    ),
                                                  if (_isOwner)
                                                    IconButton(
                                                      key: menuKey,
                                                      icon: const Icon(Icons.more_vert, size: 30, color: Colors.grey),
                                                      onPressed: () {
                                                        SchedulerBinding.instance.addPostFrameCallback((_) {
                                                          final renderBox = menuKey.currentContext?.findRenderObject() as RenderBox?;
                                                          if (renderBox != null && renderBox.hasSize) {
                                                            final offset = renderBox.localToGlobal(Offset.zero);
                                                            final size = renderBox.size;
                                                            final screenWidth = MediaQuery.of(context).size.width;
                                                            final menuOffsetX = screenWidth - (offset.dx + size.width) - 20;
                                                            showMenu(
                                                              context: context,
                                                              position: RelativeRect.fromLTRB(
                                                                offset.dx - menuOffsetX,
                                                                offset.dy,
                                                                offset.dx + size.width,
                                                                offset.dy + size.height,
                                                              ),
                                                              items: [
                                                                PopupMenuItem<String>(
                                                                  value: 'edit',
                                                                  child: ListTile(
                                                                    leading: const Icon(Icons.edit, size: 30),
                                                                    title: Text(AppLocalizations.of(context)!.edit ?? 'Edit'),
                                                                  ),
                                                                ),
                                                                PopupMenuItem<String>(
                                                                  value: 'delete',
                                                                  child: ListTile(
                                                                    leading: const Icon(Icons.delete, size: 30),
                                                                    title: Text(AppLocalizations.of(context)!.delete ?? 'Delete'),
                                                                  ),
                                                                ),
                                                              ],
                                                            ).then((value) {
                                                              if (value == 'edit') _editCard(card);
                                                              if (value == 'delete') _deleteCard(card);
                                                            });
                                                          } else {
                                                            print('RenderBox is null or has no size for card ID: ${card.id}');
                                                          }
                                                        });
                                                      },
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
                );
              },
            );
          },
        ),
        floatingActionButton: _isOwner
            ? FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Theme.of(context).colorScheme.onSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onPressed: _addCard,
          child: const Icon(Icons.add, size: 32),
        )
            : null,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).bottomAppBarTheme.color ?? Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
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
      ),
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