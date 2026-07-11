import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readme_ai/features/auth/application/auth_controller.dart';
import 'package:readme_ai/features/auth/application/auth_providers.dart';
import 'package:readme_ai/features/auth/domain/auth_exception.dart';

import '../../helpers/fake_auth_repository.dart';

ProviderContainer _container(FakeAuthRepository repository) {
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('signInWithGoogle resolves to data on success', () async {
    final repository = FakeAuthRepository();
    addTearDown(repository.dispose);
    final container = _container(repository);

    await container.read(authControllerProvider.notifier).signInWithGoogle();

    expect(container.read(authControllerProvider).hasError, isFalse);
  });

  test('signInWithGoogle surfaces failures as an error state', () async {
    final repository = FakeAuthRepository()
      ..signInError = const AuthException.unknown('boom');
    addTearDown(repository.dispose);
    final container = _container(repository);

    await container.read(authControllerProvider.notifier).signInWithGoogle();

    final state = container.read(authControllerProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<AuthException>());
  });
}
