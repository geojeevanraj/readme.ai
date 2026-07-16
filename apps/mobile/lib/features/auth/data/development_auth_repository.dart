import 'dart:async';

import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

/// Development-only [AuthRepository] that bypasses Firebase and authenticates a
/// deterministic mock user.
///
/// Selected only when `DEV_AUTH=true`. It preserves the existing auth
/// architecture: the app depends on [AuthRepository], unaware which
/// implementation is active. NEVER used in production builds.
class DevelopmentAuthRepository implements AuthRepository {
  DevelopmentAuthRepository();

  static const _mockUser = AuthUser(
    uid: 'development-user',
    email: 'geo.dev@readme.ai',
    displayName: 'Geo (Development)',
  );

  /// The fixed token the backend accepts when `DEV_AUTH=true`.
  static const _devToken = 'development-token';

  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  // Auto-authenticated on startup.
  AuthUser? _current = _mockUser;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<void> signInWithGoogle() async {
    _current = _mockUser;
    _controller.add(_current);
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }

  @override
  Future<String?> idToken() async => _current == null ? null : _devToken;

  /// Release the underlying stream controller.
  Future<void> dispose() => _controller.close();
}
