import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/auth_controller.dart';
import '../domain/auth_exception.dart';

/// The unauthenticated entry screen offering Google sign-in.
///
/// Watches [authControllerProvider] to reflect the in-flight sign-in action
/// (loading spinner, disabled button) and surfaces failures as a snackbar.
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(authControllerProvider);
    final isLoading = state.isLoading;

    ref.listen(authControllerProvider, (previous, next) {
      if (next case AsyncError(:final error)) {
        _showError(context, l10n, error);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  size: 88,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.loginTitle,
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.loginSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                _GoogleSignInButton(
                  isLoading: isLoading,
                  label: l10n.signInWithGoogle,
                  onPressed: isLoading
                      ? null
                      : () => ref
                            .read(authControllerProvider.notifier)
                            .signInWithGoogle(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showError(BuildContext context, AppLocalizations l10n, Object error) {
    // User cancellations are not errors worth interrupting the user for.
    if (error is AuthException && error.isCancellation) {
      return;
    }
    final message = error is AuthException
        ? error.displayMessage
        : l10n.signInError;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({
    required this.isLoading,
    required this.label,
    required this.onPressed,
  });

  final bool isLoading;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.login),
      label: Text(label),
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
    );
  }
}
