import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flashcard_app/screens/login_page.dart';
import 'package:flashcard_app/screens/signup_page.dart';
import 'package:flashcard_app/screens/profile_page.dart';
import 'package:flashcard_app/screens/home_page.dart';
import 'package:flashcard_app/screens/deck_page.dart';
import 'package:flashcard_app/screens/learn_page.dart';
import 'package:flashcard_app/screens/cards_page.dart';
import 'package:flashcard_app/screens/create_deck_page.dart';
import 'package:flashcard_app/screens/edit_deck_page.dart';
import 'package:flashcard_app/screens/add_cards_page.dart';
import 'package:flashcard_app/screens/edit_card_page.dart';
import 'package:flashcard_app/screens/learn_deck_page.dart';
import 'package:flashcard_app/screens/account_details_page.dart';
import 'package:flashcard_app/screens/statistics_page.dart';
import 'package:flashcard_app/screens/help_page.dart';
import 'package:flashcard_app/features/settings/settings_page.dart'; // Import SettingsPage
import 'package:flashcard_app/screens/shell/app_shell.dart';
import 'package:flashcard_app/services/api_service.dart';
import 'package:flashcard_app/services/token_store.dart';
import 'package:flashcard_app/models/deck.dart' as deck_model;
import 'package:flashcard_app/models/card.dart' as card_model;

class ErrorPage extends StatelessWidget {
  final String message;
  const ErrorPage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        ),
      ),
    );
  }
}

CustomTransitionPage<T> _transitionPage<T>(Widget child) {
  return CustomTransitionPage<T>(
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

GoRouter buildRouter(ApiService api, TokenStore tokenStore) {
  return GoRouter(
    refreshListenable: tokenStore,
    redirect: (context, state) async {
      final needAuth = state.matchedLocation.startsWith('/app');
      final token = await tokenStore.getToken();
      print('Redirect check: location=${state.matchedLocation}, fullPath=${state.fullPath}, token=$token, needAuth=$needAuth');
      if (needAuth && token == null) {
        print('Redirecting to /login due to no token');
        return '/login';
      }
      if ((state.matchedLocation == '/login' || state.matchedLocation == '/signup') && token != null) {
        print('Redirecting to /app/home due to logged in');
        return '/app/home';
      }
      return null;
    },
    errorBuilder: (context, state) => ErrorPage(message: 'Route not found: ${state.matchedLocation}'),
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/login',
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (_, __) => _transitionPage(LoginPage(api: api)),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        pageBuilder: (_, __) => _transitionPage(SignupPage(api: api)),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/home',
                name: 'home',
                pageBuilder: (_, __) => _transitionPage(HomePage(api: api)),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/decks',
                name: 'decks',
                pageBuilder: (_, __) => _transitionPage(DeckPage(api: api)),
                routes: [
                  GoRoute(
                    path: ':deckId/cards',
                    name: 'cards',
                    pageBuilder: (context, state) {
                      print('Navigating to CardsPage with deckId: ${state.pathParameters['deckId']}, extra: ${state.extra}');
                      try {
                        final deckId = int.parse(state.pathParameters['deckId']!);
                        final deck = state.extra is deck_model.Deck ? state.extra as deck_model.Deck? : null;
                        return _transitionPage(CardsPage(
                          api: api,
                          deckId: deckId,
                          deck: deck,
                        ));
                      } catch (e) {
                        print('Error in CardsPage route: $e');
                        return _transitionPage(const ErrorPage(message: 'Invalid deck ID'));
                      }
                    },
                  ),
                  GoRoute(
                    path: ':deckId/add-cards',
                    name: 'add-cards',
                    pageBuilder: (context, state) {
                      print('Navigating to AddCardPage with deckId: ${state.pathParameters['deckId']}, extra: ${state.extra}');
                      try {
                        final deckId = int.parse(state.pathParameters['deckId']!);
                        final extra = state.extra as Map<String, dynamic>? ?? {};
                        return _transitionPage(AddCardPage(
                          api: extra['api'] as ApiService? ?? api,
                          deckId: deckId,
                        ));
                      } catch (e) {
                        print('Error in AddCardPage route: $e');
                        return _transitionPage(const ErrorPage(message: 'Invalid deck ID'));
                      }
                    },
                  ),
                  GoRoute(
                    path: ':deckId/edit-card/:cardId',
                    name: 'edit-card',
                    pageBuilder: (context, state) {
                      print('Navigating to EditCardPage with deckId: ${state.pathParameters['deckId']}, cardId: ${state.pathParameters['cardId']}, extra: ${state.extra}');
                      try {
                        final deckId = int.parse(state.pathParameters['deckId']!);
                        final cardId = int.parse(state.pathParameters['cardId']!);
                        final extra = state.extra as Map<String, dynamic>? ?? {};
                        final card = extra['card'] as card_model.Card?;
                        if (card == null) {
                          print('Error: No card provided in extra');
                          return _transitionPage(const ErrorPage(message: 'Invalid card data'));
                        }
                        return _transitionPage(EditCardPage(
                          api: extra['api'] as ApiService? ?? api,
                          deckId: deckId,
                          card: card,
                        ));
                      } catch (e) {
                        print('Error in EditCardPage route: $e');
                        return _transitionPage(const ErrorPage(message: 'Invalid deck or card ID'));
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/learn',
                name: 'learn',
                pageBuilder: (_, __) => _transitionPage(LearnPage(api: api)),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/profile',
                name: 'profile',
                pageBuilder: (_, __) => _transitionPage(ProfilePage(api: api)),
                routes: [
                  GoRoute(
                    path: 'account-details',
                    name: 'account-details',
                    pageBuilder: (_, __) => _transitionPage(AccountDetailsPage(api: api)),
                  ),
                  GoRoute(
                    path: 'statistics',
                    name: 'statistics',
                    pageBuilder: (_, __) => _transitionPage(StatisticsPage(api: api)),
                  ),
                  GoRoute(
                    path: 'help',
                    name: 'help',
                    pageBuilder: (_, __) => _transitionPage(const HelpPage()),
                  ),
                  GoRoute(
                    path: 'settings',
                    name: 'settings',
                    pageBuilder: (_, __) => _transitionPage(const SettingsPage()),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/app/create-deck',
        name: 'create-deck',
        pageBuilder: (_, __) => _transitionPage(CreateDeckPage(api: api)),
      ),
      GoRoute(
        path: '/app/edit-deck/:deckId',
        name: 'edit-deck',
        pageBuilder: (context, state) {
          print('Navigating to EditDeckPage with deckId: ${state.pathParameters['deckId']}, extra: ${state.extra}');
          try {
            final deckId = int.parse(state.pathParameters['deckId']!);
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final deck = extra['deck'] as deck_model.Deck?;
            if (deck == null) {
              print('Error: No deck provided in extra');
              return _transitionPage(const ErrorPage(message: 'Invalid deck data'));
            }
            return _transitionPage(EditDeckPage(
              api: extra['api'] as ApiService? ?? api,
              deckId: deckId,
            ));
          } catch (e) {
            print('Error in EditDeckPage route: $e');
            return _transitionPage(const ErrorPage(message: 'Invalid deck ID'));
          }
        },
      ),
      GoRoute(
        path: '/app/learn-deck/:deckId',
        name: 'learn-deck',
        pageBuilder: (context, state) {
          print('Navigating to LearnDeckPage with deckId: ${state.pathParameters['deckId']}');
          try {
            final deckId = int.parse(state.pathParameters['deckId']!);
            return _transitionPage(LearnDeckPage(api: api, deckId: deckId));
          } catch (e) {
            print('Error in LearnDeckPage route: $e');
            return _transitionPage(const ErrorPage(message: 'Invalid deck ID'));
          }
        },
      ),
    ],
    initialLocation: '/login',
  );
}