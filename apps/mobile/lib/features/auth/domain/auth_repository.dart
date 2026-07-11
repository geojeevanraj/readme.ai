import 'auth_user.dart';

/// Contract for authentication operations.
///
/// The application and presentation layers depend on this interface only; the
/// concrete Firebase implementation lives in the data layer and is injected via
/// Riverpod, so it can be replaced with a fake in tests.
abstract interface class AuthRepository {
  /// Emits the current [AuthUser] (or `null` when signed out) and every
  /// subsequent change, including the persisted session restored on app start.
  Stream<AuthUser?> authStateChanges();

  /// Begin the Google sign-in flow and establish a session.
  ///
  /// Throws an `AuthException` on failure (including user cancellation).
  Future<void> signInWithGoogle();

  /// Sign out of both the identity provider and the app session.
  Future<void> signOut();

  /// Return a fresh ID token for the current user, or `null` if signed out.
  Future<String?> idToken();
}
