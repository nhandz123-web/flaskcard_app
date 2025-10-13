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

class _DeckPageState extends State<DeckPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    print('Khởi tạo DeckPage');
    WidgetsBinding.instance.addObserver(this);
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
      print('DeckPage hiển thị lại');
      widget.api.refreshDecks();
    }
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
    // Show confirmation dialog
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

                        final decks = deckProvider.decks;
                        return Container(
                          color: Theme.of(context).colorScheme.surface,
                          padding: const EdgeInsets.all(16),
                          child: ListView.builder(
                            itemCount: decks.length,
                            itemBuilder: (context, index) {
                              final deck = decks[index];
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
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _navigateToCardsPage(deck),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
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
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            onPressed: () => _handleCreateDeck(context),
            icon: const Icon(Icons.add_rounded),
            label: Text(
              AppLocalizations.of(context)!.createNewDeck ?? 'Tạo bộ thẻ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }
}