import 'package:flutter/material.dart';

import '../../../core/theme/app_semantics.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Shown while the persisted session is resolved.
///
/// Deliberately the same paper canvas and the same wordmark, in the same
/// position, as the screen that follows it: the old splash was a dark blue
/// gradient that cut to a light screen a moment later, which reads as two
/// different apps starting up. Here the launch is one continuous surface and
/// only the wordmark's opacity settles.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantics = context.semantics;

    return Scaffold(
      body: Center(
        child: TweenAnimationBuilder<double>(
          duration: Motion.of(context, Motion.slow),
          curve: Motion.standard,
          tween: Tween(begin: 0, end: 1),
          builder: (context, value, child) =>
              Opacity(opacity: value, child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: semantics.accent,
                  borderRadius: Radii.all(Radii.md),
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 22,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: Space.base),
              Text(
                l10n.appTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: semantics.inkMuted,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
