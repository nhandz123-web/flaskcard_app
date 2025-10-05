import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'services/token_store.dart';
import 'services/api_service.dart';
import 'core/settings/settings_provider.dart';
import 'core/notifications/notification_service.dart';
import 'l10n/app_localizations.dart';
import 'providers/user_provider.dart';
import 'screens/login_page.dart';
import 'screens/deck_page.dart';
import 'screens/create_deck_page.dart';
import 'screens/cards_page.dart';
import 'screens/home_page.dart';
import 'features/settings/settings_page.dart';
import 'screens/profile_page.dart';
import 'screens/edit_deck_page.dart';
import 'screens/add_cards_page.dart';
import 'screens/edit_card_page.dart';
import 'models/deck.dart' as deck_model;
import 'models/card.dart' as card_model;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.I.init();

  final tokenStore = TokenStore();
  await tokenStore.clear(); // Tạm xóa token để test

  final api = ApiService(tokenStore);
  final settings = SettingsProvider();
  await settings.load();
  final userProvider = UserProvider(api);
  try {
    await userProvider.loadUser();
  } catch (e) {
    print('Lỗi khi load user trong main: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<TokenStore>.value(value: tokenStore),
        Provider<ApiService>.value(value: api),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<UserProvider>.value(value: userProvider),
      ],
      child: MyApp(api: api, tokenStore: tokenStore),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.api, required this.tokenStore});
  final ApiService api;
  final TokenStore tokenStore;

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        print('Rebuilding MyApp with themeMode: ${settings.themeMode}, fontScale: ${settings.fontScale}, locale: ${settings.locale}');
        return MaterialApp.router(
          title: 'Flashcard',
          routerConfig: GoRouter(
            initialLocation: '/login',
            redirect: (context, state) async {
              final token = await tokenStore.getToken();
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final settings = Provider.of<SettingsProvider>(context, listen: false);
              final isAuthRoute = state.fullPath == '/login';
              final isSettingsRoute = state.fullPath == '/app/settings';
              final isCreateDeckRoute = state.fullPath == '/app/create-deck';
              final isEditDeckRoute = state.fullPath?.startsWith('/app/edit-deck/') ?? false;
              final isDecksRoute = state.fullPath == '/app/decks';
              final isAddCardsRoute = state.fullPath?.startsWith('/app/deck/') ?? false; // Đã có
              final isEditCardRoute = state.fullPath?.startsWith('/app/deck/') ?? false; // Đã có
              final currentLocation = state.fullPath;

              print('Redirect check: location=$currentLocation, lastKnownRoute=${settings.lastKnownRoute}, token=$token, userId=${userProvider.userId}, needAuth=${!isAuthRoute && !isSettingsRoute && !isCreateDeckRoute && !isEditDeckRoute && !isDecksRoute && !isAddCardsRoute && !isEditCardRoute}, isSettingsRoute=$isSettingsRoute');

              if (currentLocation != null && currentLocation != settings.lastKnownRoute) {
                settings.setLastKnownRoute(currentLocation);
              }

              if (token == null || userProvider.userId == null) {
                if (!isAuthRoute) {
                  print('Redirecting to /login due to missing token or userId');
                  return '/login';
                }
                return null;
              }

              if (token != null && userProvider.userId != null && isAuthRoute && settings.lastKnownRoute != '/app/settings' && settings.lastKnownRoute != '/app/create-deck' && !isEditDeckRoute) {
                print('Redirecting to /home due to valid token and userId');
                return '/home';
              }

              if (isSettingsRoute || isCreateDeckRoute || isEditDeckRoute || isDecksRoute || isAddCardsRoute || isEditCardRoute || (settings.lastKnownRoute != null && (settings.lastKnownRoute == '/app/settings' || settings.lastKnownRoute == '/app/create-deck' || settings.lastKnownRoute.startsWith('/app/edit-deck/') || settings.lastKnownRoute == '/app/decks' || settings.lastKnownRoute.startsWith('/app/deck/')))) {
                return null;
              }

              if (token != null && userProvider.userId != null && !isAuthRoute && !isSettingsRoute && !isCreateDeckRoute && !isEditDeckRoute && !isDecksRoute && !isAddCardsRoute && !isEditCardRoute) {
                return null;
              }

              return null;
            },
            refreshListenable: settings,
            routes: [
              GoRoute(
                path: '/',
                redirect: (context, state) => '/login',
              ),
              GoRoute(
                path: '/login',
                builder: (context, state) => LoginPage(api: api),
              ),
              GoRoute(
                path: '/home',
                builder: (context, state) => HomePage(api: api),
              ),
              GoRoute(
                path: '/app/decks',
                builder: (context, state) => DeckPage(api: api),
              ),
              GoRoute(
                path: '/app/deck/:id/cards',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return CardsPage(api: api, deckId: id, deck: state.extra as deck_model.Deck?);
                },
              ),
              GoRoute(
                path: '/app/deck/:deckId/add-cards',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  return AddCardPage(
                    api: extra['api'] as ApiService? ?? Provider.of<ApiService>(context, listen: false),
                    deckId: int.parse(state.pathParameters['deckId']!),
                  );
                },
              ),
              GoRoute(
                path: '/app/deck/:deckId/edit-card/:cardId',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>;
                  return EditCardPage(
                    api: extra['api'] as ApiService,
                    deckId: int.parse(state.pathParameters['deckId']!),
                    card: extra['card'] as card_model.Card,
                  );
                },
              ),
              GoRoute(
                path: '/app/create-deck',
                builder: (context, state) => CreateDeckPage(api: api),
              ),

              GoRoute(
                path: '/app/edit-deck/:deckId',
                builder: (context, state) {
                  final deckId = int.parse(state.pathParameters['deckId']!);
                  return EditDeckPage(api: api, deckId: deckId);
                },
              ),
              GoRoute(
                path: '/app/settings',
                builder: (context, state) => const SettingsPage(),
              ),
              GoRoute(
                path: '/app/profile',
                builder: (context, state) => ProfilePage(api: api),
              ),
              GoRoute(
                path: '/app/deck/:deckId/edit-card/:cardId',
                builder: (context, state) {
                  final deckId = int.parse(state.pathParameters['deckId']!);
                  final cardId = int.parse(state.pathParameters['cardId']!);
                  final card = state.extra as card_model.Card?;
                  if (card == null) {
                    throw Exception('Card data not provided for editing');
                  }
                  return EditCardPage(api: api, deckId: deckId, card: card);
                },
              ),
            ],
          ),
          themeMode: settings.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.grey.shade100,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith((states) => Colors.indigo),
                foregroundColor: MaterialStateProperty.resolveWith((states) => Colors.white),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                )),
              ),
            ),
            iconTheme: const IconThemeData(size: 24),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              selectedIconTheme: IconThemeData(size: 24),
              unselectedIconTheme: IconThemeData(size: 24),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.grey.shade900,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith((states) => Colors.grey[700]),
                foregroundColor: MaterialStateProperty.resolveWith((states) => Colors.white),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                )),
              ),
            ),
            iconTheme: const IconThemeData(size: 24),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              selectedIconTheme: IconThemeData(size: 24),
              unselectedIconTheme: IconThemeData(size: 24),
            ),
          ),
          locale: settings.locale,
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        );
      },
    );
  }
}