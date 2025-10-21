import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart' as pull_to_refresh;
import '../services/api_service.dart';
import '../models/deck.dart' as deck_model;
import '../core/settings/settings_provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/deck_provider.dart';
import '../providers/review_provider.dart';
import 'dart:async';

// Constants
class _Constants {
  static const Duration reviewCheckInterval = Duration(minutes: 1); // Giảm tần suất check
  static const Duration debounceDelay = Duration(milliseconds: 500);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}

class LearnPage extends StatefulWidget {
  final ApiService api;

  const LearnPage({super.key, required this.api});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> with WidgetsBindingObserver {
  Timer? _reviewCheckTimer;
  Timer? _debounceTimer;
  final pull_to_refresh.RefreshController _refreshController =
  pull_to_refresh.RefreshController(initialRefresh: false);

  bool _isRefreshing = false;
  int _retryCount = 0;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialLoad();
    _startReviewCheckTimer();
  }

  @override
  void dispose() {
    _reviewCheckTimer?.cancel();
    _debounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _refreshController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Chỉ refresh nếu đã quá 30 giây kể từ lần refresh trước
      final now = DateTime.now();
      if (_lastRefreshTime == null ||
          now.difference(_lastRefreshTime!) > const Duration(seconds: 30)) {
        _refreshData();
      }
    }
  }

  Future<void> _initialLoad() async {
    await _refreshData(showLoading: true);
  }

  Future<void> _refreshData({bool showLoading = false}) async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    _lastRefreshTime = DateTime.now();

    try {
      final deckProvider = Provider.of<DeckProvider>(context, listen: false);
      final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);

      // Parallel loading
      await Future.wait([
        widget.api.refreshDecks(),
        Future.delayed(Duration.zero), // Placeholder for other operations
      ]);

      await reviewProvider.syncReviewCounts(
        deckProvider.decks.map((d) => d.id).toList(),
        widget.api,
      );

      _retryCount = 0; // Reset retry count on success

      if (mounted) {
        _refreshController.refreshCompleted();
      }
    } catch (e) {
      debugPrint('Error refreshing data: $e');

      if (mounted) {
        _refreshController.refreshFailed();

        // Retry logic với exponential backoff
        if (_retryCount < _Constants.maxRetryAttempts) {
          _retryCount++;
          final delay = _Constants.retryDelay * _retryCount;

          await Future.delayed(delay);
          if (mounted) {
            _refreshData();
          }
        } else {
          Provider.of<ReviewProvider>(context, listen: false)
              .setError(e.toString());
        }
      }
    } finally {
      _isRefreshing = false;
    }
  }

  void _startReviewCheckTimer() {
    _reviewCheckTimer = Timer.periodic(_Constants.reviewCheckInterval, (timer) async {
      if (!mounted || _isRefreshing) return;

      final deckProvider = Provider.of<DeckProvider>(context, listen: false);
      final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
      bool hasChanges = false;

      // Check in batches to avoid overwhelming the API
      final decks = deckProvider.decks;
      for (var i = 0; i < decks.length; i++) {
        final deck = decks[i];
        try {
          final cards = await widget.api.getCardsToReview(deck.id);
          final currentCount = reviewProvider.reviewCounts[deck.id] ?? 0;
          final newCount = cards.length;

          if (newCount != currentCount) {
            reviewProvider.setReviewCount(deck.id, newCount);
            hasChanges = true;
          }
        } catch (e) {
          debugPrint('Error checking review cards for deck ${deck.id}: $e');
        }

        // Add small delay between checks
        if (i < decks.length - 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      if (hasChanges && mounted) {
        HapticFeedback.lightImpact();
        _showNewCardsSnackbar();
      }
    });
  }

  void _showNewCardsSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notification_important, color: Colors.white),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.newCardsAvailable ??
                'Có thẻ mới cần ôn tập!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(settings.fontScale),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: pull_to_refresh.SmartRefresher(
                      controller: _refreshController,
                      onRefresh: _refreshData,
                      header: const pull_to_refresh.WaterDropHeader(),
                      child: Consumer<DeckProvider>(
                        builder: (context, deckProvider, _) {
                          return Consumer<ReviewProvider>(
                            builder: (context, reviewProvider, _) {
                              return _buildContent(
                                context,
                                deckProvider,
                                reviewProvider,
                              );
                            },
                          );
                        },
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade600, Colors.red.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.school_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context)!.lexiFlash ?? 'LexiFlash',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context,
      DeckProvider deckProvider,
      ReviewProvider reviewProvider,
      ) {
    if (deckProvider.isLoading || reviewProvider.isLoading) {
      return _buildLoadingSkeleton(context);
    }

    if (deckProvider.error != null || reviewProvider.error != null) {
      return _buildErrorState(
        context,
        deckProvider.error ?? reviewProvider.error ?? 'Unknown error',
      );
    }

    if (deckProvider.decks.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildDeckGrid(context, deckProvider.decks, reviewProvider);
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
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
        itemCount: 4,
        itemBuilder: (context, index) => _DeckCardSkeleton(),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.errorLoadingDecks ?? 'Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.retry ?? 'Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noDecks ?? 'No decks available',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckGrid(
      BuildContext context,
      List<deck_model.Deck> decks,
      ReviewProvider reviewProvider,
      ) {
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
          final reviewCount = reviewProvider.reviewCounts[deck.id] ?? 0;
          return _DeckCard(
            deck: deck,
            reviewCount: reviewCount,
            onTap: () async {
              HapticFeedback.selectionClick();
              await context.push('/app/learn-deck/${deck.id}');
              _refreshData();
            },
          );
        },
      ),
    );
  }
}

// Separate widget for deck card
class _DeckCard extends StatelessWidget {
  final deck_model.Deck deck;
  final int reviewCount;
  final VoidCallback onTap;

  const _DeckCard({
    required this.deck,
    required this.reviewCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildIcon(),
                    const SizedBox(height: 12),
                    _buildTitle(context),
                    const SizedBox(height: 6),
                    Expanded(child: _buildDescription(context)),
                    const SizedBox(height: 8),
                    _buildReviewBadge(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
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
      child: const Icon(
        Icons.school_rounded,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      deck.name,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      deck.description,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildReviewBadge(BuildContext context) {
    return Container(
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
            '$reviewCount ${AppLocalizations.of(context)!.cards ?? 'cards'}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// Skeleton loading widget
class _DeckCardSkeleton extends StatefulWidget {
  @override
  State<_DeckCardSkeleton> createState() => _DeckCardSkeletonState();
}

class _DeckCardSkeletonState extends State<_DeckCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildShimmer(context, 56, 56, isCircular: true),
                const SizedBox(height: 12),
                _buildShimmer(context, double.infinity, 16),
                const SizedBox(height: 6),
                _buildShimmer(context, double.infinity, 12),
                const SizedBox(height: 4),
                _buildShimmer(context, 100, 12),
                const Spacer(),
                _buildShimmer(context, 80, 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmer(
      BuildContext context,
      double width,
      double height, {
        bool isCircular = false,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade700.withOpacity(0.3)
            : Colors.grey.shade300.withOpacity(0.5),
        borderRadius: isCircular
            ? BorderRadius.circular(height / 2)
            : BorderRadius.circular(8),
      ),
    );
  }
}