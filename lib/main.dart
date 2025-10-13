import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flashcard_app/services/token_store.dart';
import 'package:flashcard_app/services/api_service.dart';
import 'package:flashcard_app/core/settings/settings_provider.dart';
import 'package:flashcard_app/core/notifications/notification_service.dart';
import 'package:flashcard_app/l10n/app_localizations.dart';
import 'package:flashcard_app/providers/user_provider.dart';
import 'package:flashcard_app/providers/deck_provider.dart';
import 'package:flashcard_app/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.I.init();

  final tokenStore = TokenStore();
  await tokenStore.clear(); // Tạm xóa token để test

  final settings = SettingsProvider();
  await settings.load();
  final deckProvider = DeckProvider();
  final api = ApiService(tokenStore, deckProvider);
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
        ChangeNotifierProvider<DeckProvider>.value(value: deckProvider),
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
          routerConfig: buildRouter(api, tokenStore),
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