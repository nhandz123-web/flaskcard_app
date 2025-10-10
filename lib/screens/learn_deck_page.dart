import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flip_card/flip_card.dart';
import 'dart:async';
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
  List<card_model.Card> reviewCards = [];
  int currentIndex = 0;
  bool showBack = false;
  bool isLoading = true;
  bool isAudioPlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  static const String _baseUrl = 'http://10.12.216.12:8080';
  int _selectedIndex = 2;
  late Future<deck_model.Deck> _deckFuture;
  Timer? _refreshTimer;
  // Theo dõi thẻ "Học lại" và thời gian nextReviewDate
  final Map<int, DateTime> _reviewAgainCards = {};

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
    // Timer kiểm tra thẻ cần ôn lại mỗi 30 giây
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadCards();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    try {
      final data = await widget.api.getCardsToReview(widget.deckId);
      setState(() {
        // Lọc thẻ để tránh trùng lặp và chỉ thêm thẻ "Học lại" một lần
        final currentCardId = reviewCards.isNotEmpty && currentIndex < reviewCards.length
            ? reviewCards[currentIndex].id
            : null;
        final now = DateTime.now();
        final newCards = data.where((card) {
          // Không thêm thẻ đang hiển thị
          if (card.id == currentCardId) return false;
          // Nếu thẻ là "Học lại", kiểm tra xem đã được thêm chưa
          if (_reviewAgainCards.containsKey(card.id)) {
            // Chỉ thêm nếu đã qua nextReviewDate và chưa được đánh giá lại
            return now.isAfter(_reviewAgainCards[card.id]!) && !reviewCards.any((c) => c.id == card.id);
          }
          // Thêm thẻ mới hoặc thẻ không phải "Học lại"
          return !reviewCards.any((c) => c.id == card.id);
        }).toList();
        reviewCards.addAll(newCards);
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

  void _calculateSM2(card_model.Card card, int quality) async {
    double easiness = card.easiness;
    int repetition = card.repetition;
    int interval = card.interval;
    DateTime nextReviewDate;

    // Cập nhật easiness
    easiness += (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    easiness = easiness < 1.3 ? 1.3 : easiness;

    // Logic thời gian theo quality
    switch (quality) {
      case 0: // Học lại
        repetition = 0;
        interval = 1;
        nextReviewDate = DateTime.now().add(const Duration(minutes: 1));
        break;
      case 2: // Khó
        repetition = repetition > 0 ? repetition : 0;
        interval = (interval * 0.5).round().clamp(1, interval);
        nextReviewDate = DateTime.now().add(const Duration(minutes: 5));
        break;
      case 3: // Bình thường
        repetition += 1;
        interval = (interval * 1.2).round().clamp(1, double.infinity.toInt());
        nextReviewDate = DateTime.now().add(const Duration(minutes: 10));
        break;
      case 5: // Dễ
        repetition += 1;
        interval = (interval * 2.0).round().clamp(1, double.infinity.toInt());
        nextReviewDate = DateTime.now().add(const Duration(days: 1));
        break;
      default:
        return;
    }

    try {
      await widget.api.markCardReview(
        card.id,
        quality,
        easiness,
        repetition,
        interval,
        nextReviewDate,
      );
      setState(() {
        card.easiness = easiness;
        card.repetition = repetition;
        card.interval = interval;
        card.nextReviewDate = nextReviewDate;
        // Lưu thẻ "Học lại" vào _reviewAgainCards
        if (quality == 0) {
          _reviewAgainCards[card.id] = nextReviewDate;
        } else {
          _reviewAgainCards.remove(card.id); // Xóa nếu đánh giá khác "Học lại"
        }
      });
    } catch (e) {
      print('Lỗi khi cập nhật review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorMarkingCardLearned ?? 'Lỗi khi cập nhật thẻ')),
      );
    }
  }

  void _reviewCard(int quality) {
    if (currentIndex >= reviewCards.length) return;
    final card = reviewCards[currentIndex];
    _calculateSM2(card, quality);

    setState(() {
      showBack = false; // Đảm bảo thẻ mới hiển thị mặt trước
      if (quality == 0 || quality == 2) {
        // Di chuyển thẻ "Học lại" hoặc "Khó" ra cuối danh sách
        if (reviewCards.length > 1) {
          final reviewedCard = reviewCards.removeAt(currentIndex);
          reviewCards.add(reviewedCard);
          if (currentIndex >= reviewCards.length) {
            currentIndex = 0;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                quality == 0
                    ? (AppLocalizations.of(context)!.reviewAgain ?? 'Thẻ sẽ được ôn lại sau 1 phút.')
                    : (AppLocalizations.of(context)!.reviewHard ?? 'Thẻ sẽ được ôn lại sau 5 phút.'),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                quality == 0
                    ? (AppLocalizations.of(context)!.reviewAgain ?? 'Thẻ sẽ được ôn lại sau 1 phút.')
                    : (AppLocalizations.of(context)!.reviewHard ?? 'Thẻ sẽ được ôn lại sau 5 phút.'),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Xóa thẻ "Bình thường" hoặc "Dễ" khỏi danh sách
        reviewCards.removeAt(currentIndex);
        if (currentIndex >= reviewCards.length) {
          currentIndex = 0;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              quality == 3
                  ? (AppLocalizations.of(context)!.reviewNormal ?? 'Thẻ sẽ được ôn lại sau 10 phút.')
                  : (AppLocalizations.of(context)!.reviewEasy ?? 'Thẻ sẽ được ôn lại sau 1 ngày.'),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      // Chuyển sang thẻ tiếp theo nếu có
      _nextCard();
    });
  }

  void _nextCard() {
    setState(() {
      showBack = false; // Đảm bảo thẻ mới hiển thị mặt trước
      if (currentIndex < reviewCards.length - 1) {
        currentIndex++;
      } else if (reviewCards.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.completedDeck ?? 'Bạn đã học hết các thẻ cần ôn tập hôm nay!'),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.back ?? 'Quay lại',
              onPressed: () => context.go('/app/learn'),
            ),
          ),
        );
        currentIndex = 0;
        reviewCards = [];
      } else {
        currentIndex = 0; // Quay lại đầu danh sách nếu còn thẻ
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

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: CachedNetworkImage(
            imageUrl: imageUrl.startsWith('http') ? imageUrl : '$_baseUrl$imageUrl',
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => const Icon(
              Icons.broken_image,
              size: 50,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
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
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.85; // 85% chiều rộng màn hình
    final cardHeight = cardWidth * 1.5; // Tỷ lệ 2:3 cho thẻ

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
                  String title = AppLocalizations.of(context)!.learnDeckTitle(widget.deckId.toString()) ?? 'Learn Deck #${widget.deckId}';
                  if (snapshot.hasData && snapshot.data!.name.isNotEmpty) {
                    title = snapshot.data!.name;
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isLoading && reviewCards.isNotEmpty)
                        Text(
                          '${currentIndex + 1}/${reviewCards.length}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                    ],
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
                : reviewCards.isEmpty
                ? Center(
              child: Text(
                AppLocalizations.of(context)!.noCardsToReview ?? 'Không có thẻ nào cần ôn tập hôm nay.',
                style: TextStyle(
                  fontSize: 16 * settings.fontScale,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
            )
                : SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    FlipCard(
                      direction: FlipDirection.HORIZONTAL,
                      front: _buildCardSide(
                        context,
                        width: cardWidth,
                        height: cardHeight,
                        content: Text(
                          reviewCards[currentIndex].front,
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
                        width: cardWidth,
                        height: cardHeight,
                        content: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              reviewCards[currentIndex].back,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20 * settings.fontScale,
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (reviewCards[currentIndex].phonetic != null && reviewCards[currentIndex].phonetic!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '[${reviewCards[currentIndex].phonetic}]',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16 * settings.fontScale,
                                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            if (reviewCards[currentIndex].imageUrl != null && reviewCards[currentIndex].imageUrl!.isNotEmpty)
                              GestureDetector(
                                onTap: () => _showImageDialog(reviewCards[currentIndex].imageUrl!),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: reviewCards[currentIndex].imageUrl!.startsWith('http')
                                        ? reviewCards[currentIndex].imageUrl!
                                        : '$_baseUrl${reviewCards[currentIndex].imageUrl}',
                                    height: 200,
                                    width: 200,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) => const Icon(
                                      Icons.broken_image,
                                      size: 50,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            if (reviewCards[currentIndex].audioUrl != null && reviewCards[currentIndex].audioUrl!.isNotEmpty)
                              AnimatedScale(
                                scale: isAudioPlaying ? 1.2 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: IconButton(
                                  icon: Icon(
                                    isAudioPlaying ? Icons.pause : Icons.volume_up,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    size: 30,
                                  ),
                                  onPressed: () => _playAudio(reviewCards[currentIndex].audioUrl),
                                  tooltip: isAudioPlaying
                                      ? AppLocalizations.of(context)!.pauseAudio ?? 'Tạm dừng âm thanh'
                                      : AppLocalizations.of(context)!.playAudio ?? 'Phát âm thanh',
                                ),
                              ),
                            const SizedBox(height: 8),
                            if (reviewCards[currentIndex].example != null && reviewCards[currentIndex].example!.isNotEmpty)
                              Text(
                                '${AppLocalizations.of(context)!.example ?? 'Ví dụ'}: ${reviewCards[currentIndex].example}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14 * settings.fontScale,
                                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      onFlip: () => setState(() => showBack = !showBack),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
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
            persistentFooterButtons: reviewCards.isEmpty
                ? null
                : [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade600, // Xám cho "Học lại"
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _reviewCard(0),
                        child: Text(
                          AppLocalizations.of(context)!.again ?? 'Học lại',
                          style: TextStyle(fontSize: 14 * settings.fontScale),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400, // Đỏ nhạt cho "Khó"
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _reviewCard(2),
                        child: Text(
                          AppLocalizations.of(context)!.hard ?? 'Khó',
                          style: TextStyle(fontSize: 14 * settings.fontScale),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600, // Cam cho "Bình thường"
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _reviewCard(3),
                        child: Text(
                          AppLocalizations.of(context)!.normal ?? 'Bình thường',
                          style: TextStyle(fontSize: 14 * settings.fontScale),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600, // Xanh lá cho "Dễ"
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _reviewCard(5),
                        child: Text(
                          AppLocalizations.of(context)!.easy ?? 'Dễ',
                          style: TextStyle(fontSize: 14 * settings.fontScale),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardSide(BuildContext context, {required Widget content, required double width, required double height}) {
    return Container(
      width: width,
      height: height,
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