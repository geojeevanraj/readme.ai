/// Centralised route names and paths.
///
/// Referencing these constants instead of string literals keeps navigation
/// consistent and makes route changes a single-edit operation.
abstract final class AppRoutes {
  /// Splash / bootstrapping route (shown while auth state resolves).
  static const String splashName = 'splash';

  /// Path for the splash route.
  static const String splashPath = '/';

  /// Login route (unauthenticated).
  static const String loginName = 'login';

  /// Path for the login route.
  static const String loginPath = '/login';

  /// Home route (authenticated) — the user's library.
  static const String homeName = 'home';

  /// Path for the home route.
  static const String homePath = '/home';

  /// Book detail route name.
  static const String bookDetailName = 'book-detail';

  /// Path for the book detail route, relative to [homePath].
  static const String bookDetailRelativePath = 'books/:bookId';

  /// Reader route name.
  static const String readerName = 'reader';

  /// Path for the reader route, relative to the book detail route.
  static const String readerRelativePath = 'read';
}
