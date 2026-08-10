import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_semantics.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/auth_controller.dart';
import '../domain/auth_exception.dart';

/// Sign-in.
///
/// The screen shows the product rather than describing it: a real sentence set
/// in the reading face, with a phrase highlighted exactly as the reader would
/// highlight it, and the answer underneath. Someone deciding whether to hand
/// over a Google account can see what they get before they do it — which a
/// feature list never achieves.
///
/// Sign-in failures appear inline next to the button that failed (and are still
/// announced), because a snackbar that has already faded leaves a reader
/// staring at a button that "did nothing".
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantics = context.semantics;
    final state = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (next case AsyncError(:final error)) {
        if (error is AuthException && error.isCancellation) return;
        setState(() {
          _error = error is AuthException
              ? error.displayMessage
              : l10n.signInError;
        });
      }
      if (next is AsyncLoading && _error != null) {
        setState(() => _error = null);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.lg,
              vertical: Space.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _BrandMark(),
                  const SizedBox(height: Space.xxl),
                  Text(
                    l10n.loginHeadline,
                    style: TextStyle(
                      fontFamily: AppTypography.serifFamily,
                      fontFamilyFallback: AppTypography.serifFallback,
                      fontSize: 32,
                      height: 1.18,
                      letterSpacing: -0.6,
                      fontWeight: FontWeight.w600,
                      color: semantics.ink,
                    ),
                  ),
                  const SizedBox(height: Space.xxl),
                  const _ExplainDemo(),
                  const SizedBox(height: Space.xxl),

                  if (_error != null) ...[
                    _SignInError(message: _error!),
                    const SizedBox(height: Space.md),
                  ],

                  FilledButton.icon(
                    onPressed: state.isLoading
                        ? null
                        : () => ref
                              .read(authControllerProvider.notifier)
                              .signInWithGoogle(),
                    icon: state.isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.login_rounded, size: 18),
                    label: Text(
                      _error == null ? l10n.signInWithGoogle : l10n.loginRetry,
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 15,
                        color: semantics.inkFaint,
                      ),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: Text(
                          l10n.loginPrivacy,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: semantics.inkFaint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A miniature, non-interactive rehearsal of the core interaction.
class _ExplainDemo extends StatelessWidget {
  const _ExplainDemo();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantics = context.semantics;

    final passage = l10n.loginDemoPassage;
    final highlight = l10n.loginDemoHighlight;
    final start = passage.indexOf(highlight);
    final end = start == -1 ? -1 : start + highlight.length;

    final readingStyle = AppTypography.reading(
      fontSize: 18,
      lineHeight: 1.55,
      color: semantics.ink,
      serif: true,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.loginDemoLabel.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: semantics.inkMuted,
          ),
        ),
        const SizedBox(height: Space.md),
        // The passage, with the selection washed exactly as in the reader.
        Text.rich(
          start == -1
              ? TextSpan(text: passage, style: readingStyle)
              : TextSpan(
                  style: readingStyle,
                  children: [
                    TextSpan(text: passage.substring(0, start)),
                    TextSpan(
                      text: highlight,
                      style: TextStyle(
                        backgroundColor: semantics.explainHighlight,
                      ),
                    ),
                    TextSpan(text: passage.substring(end)),
                  ],
                ),
        ),
        const SizedBox(height: Space.base),
        // The answer, in the same shape as the real explanation sheet.
        Container(
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            color: semantics.surface,
            borderRadius: Radii.all(Radii.lg),
            border: Border.all(color: semantics.hairline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: semantics.accent,
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '“$highlight”',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: Space.xs),
                    Text(
                      l10n.loginDemoAnswer,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: semantics.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SignInError extends StatelessWidget {
  const _SignInError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.semantics;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          color: semantics.rustTint,
          borderRadius: Radii.all(Radii.md),
          border: Border.all(color: semantics.rust),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: semantics.rustInk,
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: semantics.rustInk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final semantics = context.semantics;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: semantics.accent,
            borderRadius: Radii.all(Radii.sm),
          ),
          child: Icon(
            Icons.auto_stories_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const SizedBox(width: Space.md),
        Text(
          l10n.appTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(letterSpacing: -0.2),
        ),
      ],
    );
  }
}
