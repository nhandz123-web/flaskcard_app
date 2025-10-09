import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flip_card/flip_card.dart';
import '../services/api_service.dart';
import '../models/card.dart' as card_model;
import '../models/deck.dart' as deck_model;
import '../l10n/app_localizations.dart';
import '../core/settings/settings_provider.dart';

class LearnDeckPage extends StatefulWidget {
  final ApiService api;
  final int deckId;

  const LearnDeckPage({
    Key? key,
    required this.api,
    required this.deckId,
  }) : super(key: key);

  @override
  State<LearnDeckPage> createState() => _LearnDeckPageState();
}

class _LearnDeckPageState extends State<LearnDeckPage> {
  List<card_model.Card> cards = [];
  int currentIndex = 0;
  bool showBack = false;
  bool isLoading = true;
  bool isAudioPlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  static const String _baseUrl = 'http://10.12.216.12:8080';
  int _selectedIndex = 2; // Learn tab được chọn
  late Future<deck_model.Deck> _deckFuture;

  @override
  void initState() {
    super.initState();
    _loadCards();
    _deckFuture = widget.api.getDeck(widget.deckId);
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        isAudioPlaying = state == PlayerState.playing;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    try {
      final data = await widget.api.getCards(widget.deckId);
      setState(() {
        cards = data;
        isLoading = false;
      });
    } catch (e) {
      print('Lỗi khi load cards: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.errorLoadingCards ?? 'Lỗi khi tải thẻ'}: $e')),
      );
    }
  }

  Future<void> _markAsLearned() async {
    if (currentIndex >= cards.length) return;
    final card = cards[currentIndex];
    try {
      await widget.api.markCardAsLearned(card.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.cardLearnedSuccessfully ?? 'Đã đánh dấu là đã học')),
      );
    } catch (e) {
      print('Lỗi khi đánh dấu học xong: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorMarkingCardLearned ?? 'Lỗi khi đánh dấu thẻ đã học')),
      );
    }
  }

  void _nextCard() {
    setState(() {
      showBack = false;
      if (currentIndex < cards.length - 1) {
        currentIndex++;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.completedDeck ?? 'Bạn đã học hết các thẻ trong deck này!')),
        );
      }
    });
  }

  Future<void> _playAudio(String? audioUrl) async {
    if (audioUrl == null || audioUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noAudio ?? 'Không có audio')),
      );
      return;
    }
    final fullAudioUrl = audioUrl.startsWith('http') ? audioUrl : '$_baseUrl$audioUrl';
    print('Attempting to play audio: $fullAudioUrl');
    try {
      if (isAudioPlaying) {
        await _audioPlayer.stop();
      } else {
        await _audioPlayer.play(UrlSource(fullAudioUrl));
      }
    } catch (e) {
      print('Lỗi khi phát âm thanh: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorPlayingAudio ?? 'Không thể phát âm thanh. Kiểm tra kết nối hoặc URL.')),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: settings.fontScale,
          ),
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.background,
            appBar: AppBar(
              title: FutureBuilder<deck_model.Deck>(
                future: _deckFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('Loading...');
                  }
                  if (snapshot.hasError) {
                    return Text(AppLocalizations.of(context)!.errorLoadingDeck ?? 'Error loading deck');
                  }
                  final deck = snapshot.data;
                  return Text(
                    deck != null && deck.name.isNotEmpty
                        ? deck.name
                        : (AppLocalizations.of(context)!.learnDeckTitle(widget.deckId.toString()) ?? 'Learn Deck #${widget.deckId}'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
              backgroundColor: Theme.of(context).brightness == Brightness.light ? Colors.red : Colors.red.shade700,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/app/learn'),
              ),
            ),
            body: isLoading
                ? const Center(child: CircularProgressIndicator())
                : cards.isEmpty
                ? Center(
              child: Text(
                AppLocalizations.of(context)!.noCards ?? 'Không có thẻ nào trong deck này.',
                style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
              ),
            )
                : Center(
              child: FlipCard(
                direction: FlipDirection.HORIZONTAL,
                front: _buildCardSide(
                  context,
                  content: Text(
                    cards[currentIndex].front,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24 * settings.fontScale,
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                back: _buildCardSide(
                  context,
                  content: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        cards[currentIndex].back,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20 * settings.fontScale,
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (cards[currentIndex].imageUrl != null && cards[currentIndex].imageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: cards[currentIndex].imageUrl!.startsWith('http')
                                ? cards[currentIndex].imageUrl!
                                : '$_baseUrl${cards[currentIndex].imageUrl}',
                            height: 200, // Tăng kích thước hình ảnh
                            width: 200,  // Tăng kích thước hình ảnh
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      if (cards[currentIndex].audioUrl != null && cards[currentIndex].audioUrl!.isNotEmpty)
                        AnimatedScale(
                          scale: isAudioPlaying ? 1.2 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: IconButton(
                            icon: Icon(
                              isAudioPlaying ? Icons.pause : Icons.volume_up,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 30,
                            ),
                            onPressed: () => _playAudio(cards[currentIndex].audioUrl),
                            tooltip: isAudioPlaying
                                ? AppLocalizations.of(context)!.pauseAudio ?? 'Tạm dừng âm thanh'
                                : AppLocalizations.of(context)!.playAudio ?? 'Phát âm thanh',
                          ),
                        ),
                      const SizedBox(height: 12),
                      if (cards[currentIndex].example != null && cards[currentIndex].example!.isNotEmpty)
                        Text(
                          '${AppLocalizations.of(context)!.example ?? 'Ví dụ'}: ${cards[currentIndex].example}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14 * settings.fontScale,
                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2, // Giảm maxLines để cân đối với hình ảnh lớn hơn
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                onFlip: () => setState(() => showBack = !showBack),
              ),
            ),
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
            persistentFooterButtons: cards.isEmpty
                ? null
                : [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: Text(AppLocalizations.of(context)!.learned ?? 'Đã học'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).brightness == Brightness.light
                          ? Colors.red
                          : Colors.red.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: _markAsLearned,
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(AppLocalizations.of(context)!.next ?? 'Tiếp theo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).brightness == Brightness.light
                          ? Colors.red
                          : Colors.red.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: _nextCard,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardSide(BuildContext context, {required Widget content}) {
    return Container(
      width: 300,
      height: 450,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: content),
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