import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flashcard_app/services/api_service.dart';
import 'package:flashcard_app/providers/user_provider.dart';
import 'package:flashcard_app/core/settings/settings_provider.dart';
import 'package:flashcard_app/l10n/app_localizations.dart';
import 'package:flashcard_app/providers/deck_provider.dart';
import 'package:flashcard_app/providers/review_provider.dart';

class HomePage extends StatefulWidget {
  final ApiService api;
  const HomePage({super.key, required this.api});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    print('Khởi tạo HomePage');
    widget.api.refreshDecks();
    // Đồng bộ review counts khi khởi tạo
    Provider.of<ReviewProvider>(context, listen: false).syncReviewCounts(
      Provider.of<DeckProvider>(context, listen: false).decks.map((deck) => deck.id).toList(),
      widget.api,
    );
  }

  void _navigateToLearn(BuildContext context) {
    context.go('/app/learn');
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 2) {
      _navigateToLearn(context);
    } else if (index == 1) {
      context.go('/app/decks', extra: {'api': widget.api});
    } else if (index == 3) {
      context.go('/app/profile');
    } else if (index == 0) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Xây dựng HomePage');
    return Consumer4<UserProvider, SettingsProvider, DeckProvider, ReviewProvider>(
      builder: (context, userProvider, settings, deckProvider, reviewProvider, child) {
        final totalDueCards = reviewProvider.reviewCounts.values.fold<int>(0, (sum, count) => sum + count);

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
                    child: Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.red.shade400, Colors.red.shade600],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 46,
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                backgroundImage: userProvider.avatarUrl != null
                                    ? NetworkImage(userProvider.avatarUrl!)
                                    : const AssetImage('assets/image/') as ImageProvider,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "${AppLocalizations.of(context)!.welcome ?? 'Xin chào'}, ${userProvider.name ?? 'User'}!",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)!.welcomeBack ?? 'Chào mừng trở lại',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),
                            // Cards Statistics
                            Container(
                              padding: const EdgeInsets.all(20),
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
                              child: Column(
                                children: [
                                  if (deckProvider.isLoading || reviewProvider.isLoading)
                                    const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: CircularProgressIndicator(color: Colors.red),
                                    )
                                  else if (deckProvider.error != null || reviewProvider.error != null)
                                    Column(
                                      children: [
                                        Icon(
                                          Icons.error_outline_rounded,
                                          size: 48,
                                          color: Colors.red.shade300,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          AppLocalizations.of(context)!.errorLoadingDecks ?? 'Lỗi tải dữ liệu',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          deckProvider.error ?? reviewProvider.error ?? '',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: () {
                                            widget.api.refreshDecks();
                                            Provider.of<ReviewProvider>(context, listen: false).syncReviewCounts(
                                              Provider.of<DeckProvider>(context, listen: false)
                                                  .decks
                                                  .map((deck) => deck.id)
                                                  .toList(),
                                              widget.api,
                                            );
                                          },
                                          child: Text(AppLocalizations.of(context)!.retry ?? 'Thử lại'),
                                        ),
                                      ],
                                    )
                                  else if (deckProvider.decks.isEmpty)
                                      Column(
                                        children: [
                                          Icon(
                                            Icons.auto_stories_rounded,
                                            size: 48,
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            AppLocalizations.of(context)!.noDecks ?? 'Chưa có bộ thẻ nào',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      )
                                    else
                                      Column(
                                        children: [
                                          Row(
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
                                                  Icons.school_rounded,
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
                                                      AppLocalizations.of(context)!.dueCards ?? 'Thẻ cần học',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '$totalDueCards ${AppLocalizations.of(context)!.cards ?? 'thẻ'}',
                                                      style: TextStyle(
                                                        fontSize: 24,
                                                        fontWeight: FontWeight.bold,
                                                        color: Theme.of(context).colorScheme.onSurface,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.flag_rounded,
                                                  color: Colors.red.shade600,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '${AppLocalizations.of(context)!.goal ?? 'Mục tiêu'}: 20 ${AppLocalizations.of(context)!.cardsPerDay ?? 'thẻ/ngày'}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.red.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Learn Now Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                  disabledBackgroundColor: Colors.red.withOpacity(0.6),
                                ),
                                onPressed: (deckProvider.isLoading || reviewProvider.isLoading || totalDueCards == 0)
                                    ? null
                                    : () => _navigateToLearn(context),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.play_circle_outline_rounded, size: 24),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(context)!.learnNow ?? 'Học ngay',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Streak
                            Container(
                              padding: const EdgeInsets.all(20),
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
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.local_fire_department_rounded,
                                      color: Colors.orange.shade600,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)!.streak ?? 'Chuỗi học tập',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '7 ${AppLocalizations.of(context)!.days ?? 'ngày'}',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.green.shade400,
                                    size: 32,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
}