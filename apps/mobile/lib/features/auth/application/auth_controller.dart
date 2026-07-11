import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

/// Drives sign-in and sign-out actions, exposing their progress as an
/// [AsyncValue] so the UI can render loading and error states.
///
/// The resulting *session* state is observed via [authStateChangesProvider];
/// this controller only models the in-flight action.
class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // No work to perform on construction; the initial state is idle data.
  }

  /// Trigger the Google sign-in flow.
  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      ref.read(authRepositoryProvider).signInWithGoogle,
    );
  }

  /// Sign the current user out.
  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(ref.read(authRepositoryProvider).signOut);
  }
}

/// Exposes the [AuthController] and its in-flight action state.
final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
