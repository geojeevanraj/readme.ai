import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/domain/auth_user.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/library/presentation/book_detail_screen.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/reader/presentation/reader_screen.dart';
import 'app_routes.dart';

/// Provides the application's [GoRouter] with authentication-aware redirects.
///
/// A stable router instance is kept; auth changes are propagated through a
/// [ValueNotifier] used as `refreshListenable`, so navigation re-evaluates the
/// redirect without rebuilding the router (preserving its internal state).
final appRouterProvider = Provider<GoRouter>((ref) {
  final authListenable = ValueNotifier<AsyncValue<AuthUser?>>(
    const AsyncLoading(),
  );
  ref.listen(
    authStateChangesProvider,
    (_, next) => authListenable.value = next,
    fireImmediately: true,
  );
  ref.onDispose(authListenable.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splashPath,
    refreshListenable: authListenable,
    redirect: (context, state) => _redirect(authListenable.value, state),
    routes: [
      GoRoute(
        path: AppRoutes.splashPath,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.loginPath,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.homePath,
        name: AppRoutes.homeName,
        builder: (context, state) => const LibraryScreen(),
        routes: [
          GoRoute(
            path: AppRoutes.bookDetailRelativePath,
            name: AppRoutes.bookDetailName,
            builder: (context, state) =>
                BookDetailScreen(bookId: state.pathParameters['bookId']!),
            routes: [
              GoRoute(
                path: AppRoutes.readerRelativePath,
                name: AppRoutes.readerName,
                builder: (context, state) =>
                    ReaderScreen(bookId: state.pathParameters['bookId']!),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Decide the destination given the current auth state and requested location.
String? _redirect(AsyncValue<AuthUser?> auth, GoRouterState state) {
  final location = state.matchedLocation;
  final onSplash = location == AppRoutes.splashPath;
  final onLogin = location == AppRoutes.loginPath;

  return switch (auth) {
    // Session still resolving: hold on the splash screen.
    AsyncLoading() => onSplash ? null : AppRoutes.splashPath,
    // Signed in: keep out of splash/login, otherwise stay put.
    AsyncData(value: final user) when user != null =>
      (onSplash || onLogin) ? AppRoutes.homePath : null,
    // Signed out or errored: force the login screen.
    _ => onLogin ? null : AppRoutes.loginPath,
  };
}
