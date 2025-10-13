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

  @override
  void initState() {
    super.initState();
    _refreshCards();
    _deckFuture = _fetchDeck();
    _checkOwnerStatus();
    print('Khởi tạo CardsPage: deckId=${widget.deckId}, deck=${widget.deck?.toJson()}');
  }

  Future<deck_model.Deck> _fetchDeck() async {
    try {
      final deck = await widget.api.getDeck(widget.deckId);
      if (mounted) {
        _updateOwnerStatus(deck);
      }
      print('Lấy Deck thành công - ID: ${deck.id}, User ID: ${deck.userId}, _isOwner: $_isOwner');
      return deck;
    } catch (e) {
      print('Lỗi lấy deck: $e');
      throw Exception('Tải deck thất bại: $e');
    }
  }

  void _refreshCards() {
    print('Làm mới cards cho deckId: ${widget.deckId}');
    if (mounted) {
      setState(() {
        _cardsFuture = widget.api.getCards(widget.deckId);
        _deckFuture = _fetchDeck();
      });
    }
  }

  void _checkOwnerStatus() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.userId != null && widget.deck != null) {
      _isOwner = userProvider.userId == widget.deck!.userId;
      print('Kiểm tra _isOwner: $_isOwner, User ID: ${userProvider.userId}, Deck User ID: ${widget.deck!.userId}');
    }
    if (mounted) setState(() {});
  }

  void _updateOwnerStatus(deck_model.Deck? deck) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (mounted && deck != null) {
      _isOwner = userProvider.userId != null && userProvider.userId == deck.userId;
      print('Cập nhật _isOwner: $_isOwner, User ID: ${userProvider.userId}, Deck User ID: ${deck.userId}');
    }
    if (mounted) setState(() {});
  }

  Future<void> _playAudio(String? audioUrl) async {
    if (audioUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noAudio ?? 'Không có âm thanh')),
      );
      return;
    }

    final fullUrl = 'http://172.31.219.12:8080$audioUrl';
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(fullUrl));
      print('Phát âm thanh: $fullUrl');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.errorPlayingAudio ?? 'Lỗi phát âm thanh'}: $e')),
      );
      print('Lỗi phát âm thanh: $e');
    }
  }

  void _editCard(card_model.Card card) async {
    print('Chuyển hướng đến chỉnh sửa card với ID: ${card.id}');
    try {
      final updatedCard = await context.push<card_model.Card>(
        '/app/decks/${widget.deckId}/edit-card/${card.id}',
        extra: {'api': widget.api, 'deckId': widget.deckId, 'card': card},
      );

      if (updatedCard != null && mounted) {
        print('Card đã được cập nhật, làm mới cards cho deckId: ${widget.deckId}');
        _refreshCards();
      }
    } catch (e) {
      print('Lỗi chuyển hướng đến EditCardPage: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chuyển hướng để chỉnh sửa card: $e')),
      );
    }
  }

  void _deleteCard(card_model.Card card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context)!.confirm ?? 'Xác nhận'),
        content: Text(AppLocalizations.of(context)!.confirmDeleteCard ?? 'Bạn có chắc muốn xóa thẻ này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel ?? 'Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete ?? 'Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        print('Thử xóa card với ID: ${card.id} từ deck ID: ${widget.deckId}');
        await widget.api.deleteCard(widget.deckId, card.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.cardDeletedSuccessfully ?? 'Xóa thẻ thành công')),
        );
        _refreshCards();
      } catch (e) {
        if (!mounted) return;
        final errorMessage = e.toString().isNotEmpty ? e.toString() : 'Lỗi không xác định';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorDeletingCard(errorMessage) ?? 'Lỗi: $errorMessage')),
        );
        print('Lỗi xóa card: $e');
      }
    }
  }

  void _addCard() async {
    print('Chuyển hướng đến AddCardPage với deckId: ${widget.deckId}');
    try {
      final result = await context.push('/app/decks/${widget.deckId}/add-cards', extra: {'api': widget.api});
      if (result == true && mounted) {
        print('Làm mới sau khi thêm card...');
        _refreshCards();
      }
    } catch (e) {
      print('Lỗi chuyển hướng đến AddCardPage: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chuyển hướng để thêm card: $e')),
      );
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('Xây dựng CardsPage cho deckId: ${widget.deckId}, _isOwner: $_isOwner');
    return WillPopScope(
      onWillPop: () async {
        context.go('/app/decks');
        return false;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: FutureBuilder(
          future: _deckFuture,
          builder: (context, AsyncSnapshot<deck_model.Deck> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.red));
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text(
                      '${AppLocalizations.of(context)!.errorLoadingDeck ?? 'Lỗi tải deck'}: ${snapshot.error}',
                      style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final deck = snapshot.data ?? widget.deck;
            if (deck == null) {
              return Center(
                child: Text(
                  AppLocalizations.of(context)!.noDeckData ?? 'Không có dữ liệu deck',
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
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              width: double.infinity,
                              color: Colors.red,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      deck.name.isNotEmpty ? deck.name : (AppLocalizations.of(context)!.lexiFlash ?? 'LexiFlash'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${deck.cardsCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => context.go('/app/decks'),
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: FutureBuilder<List<card_model.Card>>(
                            future: _cardsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator(color: Colors.red));
                              }
                              if (snapshot.hasError) {
                                return Container(
                                  color: Theme.of(context).colorScheme.surface,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
                                        const SizedBox(height: 16),
                                        Text(
                                          '${AppLocalizations.of(context)!.errorLoadingCards ?? 'Lỗi tải thẻ'}: ${snapshot.error}',
                                          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return Container(
                                  color: Theme.of(context).colorScheme.surface,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.style_rounded,
                                          size: 80,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          AppLocalizations.of(context)!.noCards ?? 'Chưa có thẻ nào',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Nhấn nút + để thêm thẻ đầu tiên',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final cards = snapshot.data!;

                              return Container(
                                color: Theme.of(context).colorScheme.surface,
                                padding: const EdgeInsets.all(16),
                                child: ListView.builder(
                                  itemCount: cards.length,
                                  itemBuilder: (context, index) {
                                    final card = cards[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
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
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    card.front ?? 'Không có mặt trước',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: Theme.of(context).colorScheme.onSurface,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    card.back ?? 'Không có mặt sau',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  if (card.createdAt != null) ...[
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      '${AppLocalizations.of(context)!.createdDate ?? 'Ngày tạo'}: ${card.createdAt!.toLocal().toString().split(' ')[0]}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (card.imageUrl != null)
                                                  Padding(
                                                    padding: const EdgeInsets.only(right: 8),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Image.network(
                                                        'http://172.31.219.12:8080${card.imageUrl}',
                                                        width: 50,
                                                        height: 50,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) => Container(
                                                          width: 50,
                                                          height: 50,
                                                          decoration: BoxDecoration(
                                                            color: Colors.grey.shade200,
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: const Icon(Icons.broken_image, size: 24),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                if (card.audioUrl != null)
                                                  Container(
                                                    margin: const EdgeInsets.only(right: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: IconButton(
                                                      icon: const Icon(Icons.volume_up_rounded),
                                                      onPressed: () => _playAudio(card.audioUrl),
                                                      color: Colors.red.shade600,
                                                      iconSize: 22,
                                                      padding: const EdgeInsets.all(8),
                                                      constraints: const BoxConstraints(),
                                                    ),
                                                  ),
                                                PopupMenuButton<String>(
                                                  icon: Icon(
                                                    Icons.more_vert_rounded,
                                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                    size: 22,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  onSelected: (value) {
                                                    print('Chọn hành động cho card ID ${card.id}: $value');
                                                    if (value == 'edit') {
                                                      _editCard(card);
                                                    } else if (value == 'delete') {
                                                      _deleteCard(card);
                                                    }
                                                  },
                                                  itemBuilder: (BuildContext context) => [
                                                    PopupMenuItem<String>(
                                                      value: 'edit',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.edit_rounded, size: 20, color: Colors.orange.shade600),
                                                          const SizedBox(width: 12),
                                                          Text(AppLocalizations.of(context)!.edit ?? 'Chỉnh sửa'),
                                                        ],
                                                      ),
                                                    ),
                                                    PopupMenuItem<String>(
                                                      value: 'delete',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.delete_rounded, size: 20, color: Colors.red.shade600),
                                                          const SizedBox(width: 12),
                                                          Text(AppLocalizations.of(context)!.delete ?? 'Xóa'),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
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
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          onPressed: _addCard,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            AppLocalizations.of(context)!.addCard ?? 'Thêm thẻ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}