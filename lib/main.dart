import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/token_store.dart';
import 'services/api_service.dart';
import 'core/settings/settings_provider.dart';
import 'core/notifications/notification_service.dart';
import 'app_router.dart';
import 'package:flashcard_app/l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.I.init();
  final tokenStore = TokenStore();
  await tokenStore.init();
  final api = ApiService(tokenStore);
  final settings = SettingsProvider();
  await settings.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<TokenStore>.value(value: tokenStore),
        Provider<ApiService>.value(value: api),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
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
    final router = buildRouter(api, tokenStore);
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        print('Rebuilding MyApp with fontScale=${settings.fontScale}, themeMode=${settings.themeMode}');
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(settings.fontScale),
          ),
          child: MaterialApp.router(
            title: 'Flashcard',
            routerConfig: router,
            themeMode: settings.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.indigo,
              brightness: Brightness.light,
              scaffoldBackgroundColor: Colors.grey[100],
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.indigo,
              brightness: Brightness.dark,
            ),
            locale: settings.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        );
      },
    );
  }
}