import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/profile_page.dart';
import 'screens/shell/app_shell.dart';
import 'services/token_store.dart';
import 'services/api_service.dart';
import 'features/settings/settings_page.dart';

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
          position: Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero)
              .animate(curved),
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
      final token = tokenStore.token;
      print('Redirect check: location=${state.matchedLocation}, fullPath=${state.fullPath}, '
          'token=$token, needAuth=$needAuth');
      if (needAuth && token == null) {
        print('Redirecting to /login due to no token');
        return '/login';
      }
      if ((state.matchedLocation == '/login' || state.matchedLocation == '/signup') &&
          token != null) {
        print('Redirecting to /app/home due to logged in');
        return '/app/home';
      }
      return null; // Giữ nguyên
    },
    routes: [
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
      // ✅ Sử dụng StatefulShellRoute cho AppShell
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/home',
                name: 'home',
                pageBuilder: (_, __) => _transitionPage(const _Stub('Home')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/decks',
                name: 'decks',
                pageBuilder: (_, __) => _transitionPage(const _Stub('Decks')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/app/learn',
                name: 'learn',
                pageBuilder: (_, __) => _transitionPage(const _Stub('Learn')),
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
    ],
    initialLocation: '/login',
  );
}

class _Stub extends StatelessWidget {
  const _Stub(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(child: Text('$title screen placeholder')),
  );
}
