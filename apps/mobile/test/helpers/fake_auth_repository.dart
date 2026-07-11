import 'dart:async';

import 'package:readme_ai/features/auth/domain/auth_repository.dart';
import 'package:readme_ai/features/auth/domain/auth_user.dart';

/// In-memory [AuthRepository] for widget and unit tests.
///
/// Emits an initial session value followed by any changes pushed by
/// [signInWithGoogle]/[signOut]. Set [signInError] to make sign-in fail.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthUser? initialUser}) : _current = initialUser;

  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();
  AuthUser? _current;

  /// When set, [signInWithGoogle] throws this instead of succeeding.
  Object? signInError;

  static const _signedInUser = AuthUser(
    uid: 'fake-uid',
    email: 'reader@example.com',
    displayName: 'Test Reader',
  );

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<void> signInWithGoogle() async {
    final error = signInError;
    if (error != null) {
      throw error;
    }
    _current = _signedInUser;
    _controller.add(_current);
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }

  @override
  Future<String?> idToken() async => _current == null ? null : 'fake-token';

  /// Release the underlying stream controller.
  Future<void> dispose() => _controller.close();
}
