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
import '../providers/deck_provider.dart';
import '../providers/review_provider.dart';

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
  static const String _baseUrl = 'http://10.211.73.12:8080';
  late Future<deck_model.Deck> _deckFuture;
  Timer? _refreshTimer;
  final Map<int, DateTime> _reviewAgainCards = {};
  GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();
  late DeckProvider _deckProvider;
  late ReviewProvider _reviewProvider;
  StreamSubscription<PlayerState>? _audioPlayerSubscription; // Khai báo biến

  @override
  void initState() {
    super.initState();
    _deckProvider = Provider.of<DeckProvider>(context, listen: false);
    _reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    _loadCards();
    _deckFuture = widget.api.getDeck(widget.deckId);
    _audioPlayerSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          isAudioPlaying = state == PlayerState.playing;
        });
      }
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadCards();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _audioPlayerSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    try {
      final data = await widget.api.getCardsToReview(widget.deckId);
      if (mounted) {
        setState(() {
          final currentCardId = reviewCards.isNotEmpty && currentIndex < reviewCards.length
              ? reviewCards[currentIndex].id
              : null;
          final now = DateTime.now();
          final newCards = data.where((card) {
            if (card.id == currentCardId) return false;
            if (_reviewAgainCards.containsKey(card.id)) {
              return now.isAfter(_reviewAgainCards[card.id]!) && !reviewCards.any((c) => c.id == card.id);
            }
            return !reviewCards.any((c) => c.id == card.id);
          }).toList();
          reviewCards.addAll(newCards);
          isLoading = false;
        });
        _reviewProvider.setReviewCount(widget.deckId, data.length);
        print('Loaded ${data.length} cards for review, updated review count for deck ${widget.deckId}');
      }
    } catch (e) {
      print('Lỗi khi load cards: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorLoadingCards ?? 'Lỗi khi tải thẻ'}: $e')),
        );
      }
    }
  }

  void _calculateSM2(card_model.Card card, int quality) async {
    double easiness = card.easiness ?? 2.5;
    int repetition = card.repetition ?? 0;
    int interval = card.interval ?? 1;
    DateTime nextReviewDate;

    easiness = easiness + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (easiness < 1.3) easiness = 1.3;
    if (easiness > 2.5) easiness = 2.5;

    switch (quality) {
      case 0:
        repetition = 0;
        interval = 1;
        nextReviewDate = DateTime.now().add(const Duration(minutes: 10));
        break;
      case 2:
        if (repetition == 0) {
          interval = 1;
          nextReviewDate = DateTime.now().add(const Duration(hours: 4));
        } else {
          repetition = (repetition - 1).clamp(0, repetition);
          interval = (interval * 0.7).round().clamp(1, double.infinity.toInt());
          if (interval == 1) {
            nextReviewDate = DateTime.now().add(const Duration(hours: 4));
          } else if (interval <= 3) {
            nextReviewDate = DateTime.now().add(Duration(days: interval));
          } else {
            nextReviewDate = DateTime.now().add(Duration(days: interval));
          }
        }
        break;
      case 3:
        repetition += 1;
        if (repetition == 1) {
          interval = 1;
          nextReviewDate = DateTime.now().add(const Duration(hours: 12));
        } else if (repetition == 2) {
          interval = 3;
          nextReviewDate = DateTime.now().add(const Duration(days: 3));
        } else {
          interval = (interval * easiness).round();
          nextReviewDate = DateTime.now().add(Duration(days: interval));
        }
        break;
      case 5:
        repetition += 1;
        if (repetition == 1) {
          interval = 2;
          nextReviewDate = DateTime.now().add(const Duration(days: 2));
        } else if (repetition == 2) {
          interval = 5;
          nextReviewDate = DateTime.now().add(const Duration(days: 5));
        } else {
          interval = (interval * easiness * 1.3).round();
          interval = interval.clamp(1, 180);
          nextReviewDate = DateTime.now().add(Duration(days: interval));
        }
        break;
      default:
        return;
    }

    try {
      print('Marking review for card ${card.id} with quality $quality');
      await widget.api.markCardReview(
        card.id,
        widget.deckId,
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

        if (quality == 0) {
          _reviewAgainCards[card.id] = nextReviewDate;
        } else {
          _reviewAgainCards.remove(card.id);
        }
      });
    } catch (e) {
      print('Lỗi khi cập nhật review card ${card.id}: $e');
      if (!mounted) return;
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
      showBack = false;
      if (cardKey.currentState?.isFront == false) {
        cardKey.currentState?.toggleCard();
      }

      if (quality == 0 || quality == 2) {
        if (reviewCards.length > 1) {
          final reviewedCard = reviewCards.removeAt(currentIndex);
          reviewCards.add(reviewedCard);
          if (currentIndex >= reviewCards.length) {
            currentIndex = 0;
          }
          String message = '';
          if (quality == 0) {
            message = 'Thẻ sẽ được ôn lại sau 10 phút.';
          } else {
            message = card.repetition == 0
                ? 'Thẻ sẽ được ôn lại sau 4 giờ.'
                : 'Thẻ sẽ được ôn lại sau ${card.interval} ngày.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          String message = '';
          if (quality == 0) {
            message = 'Thẻ sẽ được ôn lại sau 10 phút.';
          } else {
            message = card.repetition == 0
                ? 'Thẻ sẽ được ôn lại sau 4 giờ.'
                : 'Thẻ sẽ được ôn lại sau ${card.interval} ngày.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        reviewCards.removeAt(currentIndex);
        if (currentIndex >= reviewCards.length) {
          currentIndex = 0;
        }
        String message = '';
        if (quality == 3) {
          if (card.repetition == 1) {
            message = 'Thẻ sẽ được ôn lại sau 12 giờ.';
          } else if (card.repetition == 2) {
            message = 'Thẻ sẽ được ôn lại sau 3 ngày.';
          } else {
            message = 'Thẻ sẽ được ôn lại sau ${card.interval} ngày.';
          }
        } else { // quality == 5
          if (card.repetition == 1) {
            message = 'Thẻ sẽ được ôn lại sau 2 ngày.';
          } else if (card.repetition == 2) {
            message = 'Thẻ sẽ được ôn lại sau 5 ngày.';
          } else {
            message = 'Thẻ sẽ được ôn lại sau ${card.interval} ngày.';
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      _nextCard();
    });
  }

  void _nextCard() {
    setState(() {
      showBack = false;
      cardKey = GlobalKey<FlipCardState>();

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
        currentIndex = 0;
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorPlayingAudio ?? 'Không thể phát âm thanh.')),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.85;
    final cardHeight = cardWidth * 1.4;

    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: settings.fontScale,
          ),
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.background,
            body: SafeArea(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        width: double.infinity,
                        color: Colors.red,
                        child: FutureBuilder<deck_model.Deck>(
                          future: _deckFuture,
                          builder: (context, snapshot) {
                            String title = 'Deck #${widget.deckId}';
                            if (snapshot.hasData && snapshot.data!.name.isNotEmpty) {
                              title = snapshot.data!.name;
                            }
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!isLoading && reviewCards.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${currentIndex + 1}/${reviewCards.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => context.go('/app/learn'),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator(color: Colors.red))
                          : reviewCards.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.celebration_rounded,
                              size: 80,
                              color: Colors.green.shade400,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              AppLocalizations.of(context)!.noCardsToReview ?? 'Không có thẻ nào cần ôn tập!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bạn đã hoàn thành hết thẻ hôm nay',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                          : SingleChildScrollView(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 30),
                              FlipCard(
                                key: cardKey,
                                direction: FlipDirection.HORIZONTAL,
                                front: _buildCardSide(
                                  context,
                                  width: cardWidth,
                                  height: cardHeight,
                                  content: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.school_rounded,
                                        size: 40,
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        reviewCards[currentIndex].front,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 28,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        'Nhấn để xem đáp án',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.7),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                back: _buildCardSide(
                                  context,
                                  width: cardWidth,
                                  height: cardHeight,
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          reviewCards[currentIndex].back,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (reviewCards[currentIndex].phonetic != null &&
                                            reviewCards[currentIndex].phonetic!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 12),
                                            child: Text(
                                              '[${reviewCards[currentIndex].phonetic}]',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.white.withOpacity(0.8),
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 16),
                                        if (reviewCards[currentIndex].imageUrl != null &&
                                            reviewCards[currentIndex].imageUrl!.isNotEmpty)
                                          GestureDetector(
                                            onTap: () => _showImageDialog(reviewCards[currentIndex].imageUrl!),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: CachedNetworkImage(
                                                imageUrl: reviewCards[currentIndex].imageUrl!.startsWith('http')
                                                    ? reviewCards[currentIndex].imageUrl!
                                                    : '$_baseUrl${reviewCards[currentIndex].imageUrl}',
                                                height: 180,
                                                width: 180,
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
                                        if (reviewCards[currentIndex].audioUrl != null &&
                                            reviewCards[currentIndex].audioUrl!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 12),
                                            child: IconButton(
                                              icon: Icon(
                                                isAudioPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                                color: Colors.white,
                                                size: 48,
                                              ),
                                              onPressed: () => _playAudio(reviewCards[currentIndex].audioUrl),
                                            ),
                                          ),
                                        if (reviewCards[currentIndex].example != null &&
                                            reviewCards[currentIndex].example!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 16),
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${AppLocalizations.of(context)!.example ?? 'Ví dụ'}: ${reviewCards[currentIndex].example}',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white.withOpacity(0.9),
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                onFlip: () => setState(() => showBack = !showBack),
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!isLoading && reviewCards.isNotEmpty)
                    Container(
                      color: Theme.of(context).colorScheme.surface,
                      padding: const EdgeInsets.all(16),
                      child: showBack
                          ? Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () => _reviewCard(0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.refresh_rounded, size: 20),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context)!.again ?? 'Học lại',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () => _reviewCard(2),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.sentiment_dissatisfied_rounded, size: 20),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context)!.hard ?? 'Khó',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () => _reviewCard(3),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.sentiment_neutral_rounded, size: 20),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context)!.normal ?? 'Bình thường',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () => _reviewCard(5),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.sentiment_very_satisfied_rounded, size: 20),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context)!.easy ?? 'Dễ',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                          : Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.touch_app_rounded,
                              color: Colors.grey.shade600,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Hãy lật thẻ để xem đáp án trước',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildCardSide(BuildContext context, {required Widget content, required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red.shade500,
            Colors.red.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: content,
      ),
    );
  }
}