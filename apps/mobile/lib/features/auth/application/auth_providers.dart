import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_config.dart';
import '../data/development_auth_repository.dart';
import '../data/firebase_auth_repository.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

/// Provides the [AuthRepository] implementation, chosen by configuration.
///
/// In development mode (`DEV_AUTH=true`) a mock repository auto-authenticates a
/// local user; otherwise the Firebase implementation is used unchanged. The
/// selection lives here only — no conditional logic leaks into other modules.
/// Overridden in tests with a fake.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (ref.watch(appConfigProvider).devAuth) {
    final repository = DevelopmentAuthRepository();
    ref.onDispose(repository.dispose);
    return repository;
  }
  return FirebaseAuthRepository(
    firebaseAuth: FirebaseAuth.instance,
    googleSignIn: GoogleSignIn.instance,
  );
});

/// The source of truth for authentication state across the app.
///
/// Emits the persisted user on startup, and updates on sign-in/out. The router
/// listens to this to enforce protected navigation.
final authStateChangesProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});
