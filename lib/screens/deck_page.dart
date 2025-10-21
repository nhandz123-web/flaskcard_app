import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/deck.dart' as deck_model;
import '../core/settings/settings_provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/deck_provider.dart';

class DeckPage extends StatefulWidget {
  final ApiService api;

  const DeckPage({super.key, required this.api});

  @override
  State<DeckPage> createState() => _DeckPageState();
}

class _DeckPageState extends State<DeckPage> with WidgetsBindingObserver, TickerProviderStateMixin {
  String _sortBy = 'name'; // 'name', 'count', 'date'
  bool _sortAscending = true;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    print('Khởi tạo DeckPage');
    WidgetsBinding.instance.addObserver(this);

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabScaleAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      print('DeckPage hiển thị lại');
      widget.api.refreshDecks();
    }
  }

  List<deck_model.Deck> _sortDecks(List<deck_model.Deck> decks) {
    final sortedDecks = List<deck_model.Deck>.from(decks);

    switch (_sortBy) {
      case 'name':
        sortedDecks.sort((a, b) => _sortAscending
            ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
            : b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 'count':
        sortedDecks.sort((a, b) => _sortAscending
            ? a.cardsCount.compareTo(b.cardsCount)
            : b.cardsCount.compareTo(a.cardsCount));
        break;
      case 'date':
        sortedDecks.sort((a, b) => _sortAscending
            ? a.createdAt.compareTo(b.createdAt)
            : b.createdAt.compareTo(a.createdAt));
        break;
    }

    return sortedDecks;
  }

  Future<void> _navigateToCardsPage(deck_model.Deck deck) async {
    print('Chuyển hướng đến CardsPage với deckId: ${deck.id}, deck: ${deck.toJson()}');
    try {
      await context.push('/app/decks/${deck.id}/cards', extra: {'api': widget.api, 'deck': deck});
      print('Quay lại từ CardsPage');
    } catch (e) {
      print('Lỗi chuyển hướng đến CardsPage: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.errorNavigating ?? 'Lỗi điều hướng'}: $e'),
        ),
      );
    }
  }

  Future<void> _handleDeleteDeck(BuildContext context, int deckId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.delete ?? 'Xóa'),
        content: Text('Bạn có chắc chắn muốn xóa bộ thẻ này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await context.read<ApiService>().deleteDeck(deckId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.deckDeletedSuccessfully ?? 'Xóa deck thành công')),
      );
    } catch (e) {
      print('Lỗi xóa deck: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.errorDeletingDeck ?? 'Lỗi'}: $e')),
      );
    }
  }

  Future<void> _handleEditDeck(BuildContext context, int deckId) async {
    try {
      final deck = await context.read<ApiService>().getDeck(deckId);
      await context.push('/app/edit-deck/$deckId', extra: {'api': widget.api, 'deck': deck});
      print('Quay lại từ EditDeckPage');
    } catch (e) {
      print('Lỗi chỉnh sửa deck: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.errorLoadingDeck ?? 'Lỗi'}: $e')),
      );
    }
  }

  Future<void> _handleAddCards(BuildContext context, int deckId) async {
    print('Chuyển hướng đến AddCardPage với deckId: $deckId');
    try {
      await context.push('/app/decks/$deckId/add-cards', extra: {'api': widget.api});
      print('Quay lại từ AddCardPage');
    } catch (e) {
      print('Lỗi chuyển hướng đến AddCardPage: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chuyển hướng để thêm card: $e')),
      );
    }
  }

  Future<void> _handleCreateDeck(BuildContext context) async {
    print('Chuyển hướng đến CreateDeckPage');
    try {
      await context.push('/app/create-deck', extra: {'api': widget.api});
      print('Quay lại từ CreateDeckPage');
    } catch (e) {
      print('Lỗi chuyển hướng đến CreateDeckPage: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chuyển hướng để tạo deck: $e')),
      );
    }
  }

  Widget _buildStatisticsCard(BuildContext context, List<deck_model.Deck> decks) {
    final totalCards = decks.fold<int>(0, (sum, deck) => sum + deck.cardsCount);
    final avgCards = decks.isEmpty ? 0 : (totalCards / decks.length).round();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.auto_stories_rounded,
            value: '${decks.length}',
            label: 'Bộ thẻ',
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          _buildStatItem(
            icon: Icons.style_rounded,
            value: '$totalCards',
            label: 'Tổng thẻ',
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          _buildStatItem(
            icon: Icons.analytics_rounded,
            value: '$avgCards',
            label: 'TB/bộ',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String value, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    print('Xây dựng DeckPage');
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
                    child:                       Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.lexiFlash ?? 'LexiFlash',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildSearchBar(context),
                  Expanded(
                    child: Consumer<DeckProvider>(
                      builder: (context, deckProvider, child) {
                        print('DeckProvider state: loading=${deckProvider.isLoading}, decks=${deckProvider.decks.length}, error=${deckProvider.error}');

                        if (deckProvider.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(color: Colors.red),
                          );
                        }

                        if (deckProvider.error != null) {
                          return Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    size: 64,
                                    color: Colors.red.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    AppLocalizations.of(context)!.errorLoadingDecks ?? 'Lỗi tải dữ liệu',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    deckProvider.error ?? '',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => widget.api.refreshDecks(),
                                    child: Text(AppLocalizations.of(context)!.retry ?? 'Thử lại'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (deckProvider.decks.isEmpty) {
                          return Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.auto_stories_rounded,
                                    size: 80,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    AppLocalizations.of(context)!.noDecks ?? 'Chưa có bộ thẻ nào',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Nhấn nút + để tạo bộ thẻ đầu tiên',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final sortedDecks = _sortDecks(deckProvider.decks);

                        return Container(
                          color: Theme.of(context).colorScheme.surface,
                          child: Column(
                            children: [
                              _buildStatisticsCard(context, deckProvider.decks),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: sortedDecks.length,
                                  itemBuilder: (context, index) {
                                    final deck = sortedDecks[index];
                                    return TweenAnimationBuilder<double>(
                                      duration: Duration(milliseconds: 300 + (index * 50)),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, value, child) {
                                        return Transform.translate(
                                          offset: Offset(0, 20 * (1 - value)),
                                          child: Opacity(
                                            opacity: value,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Container(
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
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(16),
                                          onTap: () => _navigateToCardsPage(deck),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              children: [
                                                Hero(
                                                  tag: 'deck_${deck.id}',
                                                  child: Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [Colors.red.shade400, Colors.red.shade600],
                                                      ),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: const Icon(
                                                      Icons.auto_stories_rounded,
                                                      color: Colors.white,
                                                      size: 28,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        deck.name,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          color: Theme.of(context).colorScheme.onSurface,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        deck.description,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: Colors.red.withOpacity(0.1),
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
                                                                  '${deck.cardsCount}',
                                                                  style: TextStyle(
                                                                    fontSize: 12,
                                                                    fontWeight: FontWeight.w600,
                                                                    color: Colors.red.shade700,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            deck.createdAt.toLocal().toString().split(' ')[0],
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                PopupMenuButton<String>(
                                                  icon: Icon(
                                                    Icons.more_vert_rounded,
                                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  onSelected: (value) async {
                                                    print('Chọn hành động cho deck ID ${deck.id}: $value');
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
                                                      value: 'add_cards',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.add_card_rounded, size: 20, color: Colors.blue.shade600),
                                                          const SizedBox(width: 12),
                                                          Text(AppLocalizations.of(context)!.addCards ?? 'Thêm thẻ'),
                                                        ],
                                                      ),
                                                    ),
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
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ScaleTransition(
                scale: _fabScaleAnimation,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: PopupMenuButton<String>(
                    icon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 12),
                        Icon(
                          _sortBy == 'name'
                              ? Icons.sort_by_alpha_rounded
                              : _sortBy == 'count'
                              ? Icons.numbers_rounded
                              : Icons.access_time_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          color: Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    offset: const Offset(0, -8),
                    onSelected: (value) {
                      setState(() {
                        if (value == _sortBy) {
                          _sortAscending = !_sortAscending;
                        } else {
                          _sortBy = value;
                          _sortAscending = true;
                        }
                      });
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'name',
                        child: Row(
                          children: [
                            Icon(
                              Icons.sort_by_alpha_rounded,
                              size: 20,
                              color: _sortBy == 'name' ? Colors.red : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Theo tên (A-Z)',
                              style: TextStyle(
                                fontWeight: _sortBy == 'name' ? FontWeight.bold : FontWeight.normal,
                                color: _sortBy == 'name' ? Colors.red : null,
                              ),
                            ),
                            if (_sortBy == 'name') ...[
                              const Spacer(),
                              Icon(
                                _sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                size: 16,
                                color: Colors.red,
                              ),
                            ],
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'count',
                        child: Row(
                          children: [
                            Icon(
                              Icons.numbers_rounded,
                              size: 20,
                              color: _sortBy == 'count' ? Colors.red : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Theo số lượng thẻ',
                              style: TextStyle(
                                fontWeight: _sortBy == 'count' ? FontWeight.bold : FontWeight.normal,
                                color: _sortBy == 'count' ? Colors.red : null,
                              ),
                            ),
                            if (_sortBy == 'count') ...[
                              const Spacer(),
                              Icon(
                                _sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                size: 16,
                                color: Colors.red,
                              ),
                            ],
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'date',
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 20,
                              color: _sortBy == 'date' ? Colors.red : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Theo ngày tạo',
                              style: TextStyle(
                                fontWeight: _sortBy == 'date' ? FontWeight.bold : FontWeight.normal,
                                color: _sortBy == 'date' ? Colors.red : null,
                              ),
                            ),
                            if (_sortBy == 'date') ...[
                              const Spacer(),
                              Icon(
                                _sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                size: 16,
                                color: Colors.red,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ScaleTransition(
                scale: _fabScaleAnimation,
                child: FloatingActionButton.extended(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  onPressed: () => _handleCreateDeck(context),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    AppLocalizations.of(context)!.createNewDeck ?? 'Tạo bộ thẻ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}