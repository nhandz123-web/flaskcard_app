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
import 'package:flashcard_app/providers/review_provider.dart';
import 'package:flashcard_app/app_router.dart';
import 'package:go_router/go_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.microtask(() async {
    await NotificationService.I.init();
  });

  final tokenStore = TokenStore();
  await tokenStore.clear(); // Tạm xóa token để test

  final settings = SettingsProvider();
  await Future.microtask(() => settings.load());
  final deckProvider = DeckProvider();
  final reviewProvider = ReviewProvider();
  final api = ApiService(tokenStore, deckProvider, reviewProvider);
  final userProvider = UserProvider(api);
  await Future.microtask(() async {
    try {
      await userProvider.loadUser();
    } catch (e) {
      print('Lỗi khi load user trong main: $e');
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<TokenStore>.value(value: tokenStore),
        ChangeNotifierProvider<DeckProvider>.value(value: deckProvider),
        ChangeNotifierProvider<ReviewProvider>.value(value: reviewProvider),
        Provider<ApiService>.value(value: api),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<UserProvider>.value(value: userProvider),
      ],
      child: MyApp(api: api, tokenStore: tokenStore),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.api, required this.tokenStore});

  final ApiService api;
  final TokenStore tokenStore;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Tạo router một lần duy nhất trong initState
    _router = buildRouter(widget.api, widget.tokenStore);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<SettingsProvider, (ThemeMode, Locale, double)>(
      selector: (_, settings) => (settings.themeMode, settings.locale, settings.fontScale),
      builder: (context, settings, child) {
        final (themeMode, locale, fontScale) = settings;
        print('Rebuilding MyApp with themeMode: $themeMode, locale: ${locale.languageCode}, fontScale: $fontScale');

        // Hàm để áp dụng fontScale cho TextTheme
        TextTheme scaleTextTheme(TextTheme textTheme, double scale) {
          return TextTheme(
            displayLarge: textTheme.displayLarge?.copyWith(fontSize: (textTheme.displayLarge?.fontSize ?? 57) * scale),
            displayMedium: textTheme.displayMedium?.copyWith(fontSize: (textTheme.displayMedium?.fontSize ?? 45) * scale),
            displaySmall: textTheme.displaySmall?.copyWith(fontSize: (textTheme.displaySmall?.fontSize ?? 36) * scale),
            headlineLarge: textTheme.headlineLarge?.copyWith(fontSize: (textTheme.headlineLarge?.fontSize ?? 32) * scale),
            headlineMedium: textTheme.headlineMedium?.copyWith(fontSize: (textTheme.headlineMedium?.fontSize ?? 28) * scale),
            headlineSmall: textTheme.headlineSmall?.copyWith(fontSize: (textTheme.headlineSmall?.fontSize ?? 24) * scale),
            titleLarge: textTheme.titleLarge?.copyWith(fontSize: (textTheme.titleLarge?.fontSize ?? 22) * scale),
            titleMedium: textTheme.titleMedium?.copyWith(fontSize: (textTheme.titleMedium?.fontSize ?? 16) * scale),
            titleSmall: textTheme.titleSmall?.copyWith(fontSize: (textTheme.titleSmall?.fontSize ?? 14) * scale),
            bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: (textTheme.bodyLarge?.fontSize ?? 16) * scale),
            bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: (textTheme.bodyMedium?.fontSize ?? 14) * scale),
            bodySmall: textTheme.bodySmall?.copyWith(fontSize: (textTheme.bodySmall?.fontSize ?? 12) * scale),
            labelLarge: textTheme.labelLarge?.copyWith(fontSize: (textTheme.labelLarge?.fontSize ?? 14) * scale),
            labelMedium: textTheme.labelMedium?.copyWith(fontSize: (textTheme.labelMedium?.fontSize ?? 12) * scale),
            labelSmall: textTheme.labelSmall?.copyWith(fontSize: (textTheme.labelSmall?.fontSize ?? 11) * scale),
          );
        }

        return MaterialApp.router(
          key: ValueKey('$themeMode-${locale.languageCode}-$fontScale'), // Key để force rebuild khi cần
          title: 'Flashcard',
          routerConfig: _router, // Sử dụng router đã tạo từ initState
          themeMode: themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.grey.shade100,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              titleTextStyle: TextStyle(
                fontSize: 20 * fontScale,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.indigo),
                foregroundColor: WidgetStateProperty.all(Colors.white),
                shape: WidgetStateProperty.all(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                )),
                textStyle: WidgetStateProperty.all(
                  TextStyle(fontSize: 16 * fontScale),
                ),
              ),
            ),
            textTheme: scaleTextTheme(ThemeData.light().textTheme, fontScale),
            iconTheme: IconThemeData(size: 24 * fontScale),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              selectedIconTheme: IconThemeData(size: 24 * fontScale),
              unselectedIconTheme: IconThemeData(size: 24 * fontScale),
              selectedLabelStyle: TextStyle(fontSize: 12 * fontScale),
              unselectedLabelStyle: TextStyle(fontSize: 12 * fontScale),
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
              titleTextStyle: TextStyle(
                fontSize: 20 * fontScale,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.grey[700]),
                foregroundColor: WidgetStateProperty.all(Colors.white),
                shape: WidgetStateProperty.all(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                )),
                textStyle: WidgetStateProperty.all(
                  TextStyle(fontSize: 16 * fontScale),
                ),
              ),
            ),
            textTheme: scaleTextTheme(ThemeData.dark().textTheme, fontScale),
            iconTheme: IconThemeData(size: 24 * fontScale),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              selectedIconTheme: IconThemeData(size: 24 * fontScale),
              unselectedIconTheme: IconThemeData(size: 24 * fontScale),
              selectedLabelStyle: TextStyle(fontSize: 12 * fontScale),
              unselectedLabelStyle: TextStyle(fontSize: 12 * fontScale),
            ),
          ),
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
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