import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/auth_controller.dart';
import '../domain/auth_exception.dart';

/// Responsive sign-in experience for ReadMe.ai.
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (next case AsyncError(:final error)) {
        _showError(context, l10n, error);
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          const Positioned(
            top: -130,
            right: -90,
            child: _Glow(color: AppColors.apricot, size: 320),
          ),
          const Positioned(
            bottom: -160,
            left: -100,
            child: _Glow(color: AppColors.lavender, size: 380),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 860;
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 56 : 24,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 48,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1160),
                        child: wide
                            ? Row(
                                children: [
                                  const Expanded(flex: 6, child: _HeroCopy()),
                                  const SizedBox(width: 72),
                                  Expanded(
                                    flex: 4,
                                    child: _SignInCard(
                                      isLoading: state.isLoading,
                                      onPressed: state.isLoading
                                          ? null
                                          : () => ref
                                                .read(
                                                  authControllerProvider
                                                      .notifier,
                                                )
                                                .signInWithGoogle(),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const _HeroCopy(compact: true),
                                  const SizedBox(height: 36),
                                  _SignInCard(
                                    isLoading: state.isLoading,
                                    onPressed: state.isLoading
                                        ? null
                                        : () => ref
                                              .read(
                                                authControllerProvider.notifier,
                                              )
                                              .signInWithGoogle(),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, AppLocalizations l10n, Object error) {
    if (error is AuthException && error.isCancellation) return;
    final message = error is AuthException
        ? error.displayMessage
        : l10n.signInError;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: child,
        ),
      ),
      child: Column(
        crossAxisAlignment: compact
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          const _BrandMark(),
          SizedBox(height: compact ? 28 : 48),
          Text(
            'Read less.\nUnderstand more.',
            textAlign: compact ? TextAlign.center : TextAlign.left,
            style:
                (compact
                        ? theme.textTheme.displaySmall
                        : theme.textTheme.displayLarge)
                    ?.copyWith(fontSize: compact ? 44 : 70),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              'Your calm, AI-powered reading space. Turn difficult passages '
              'into clear ideas without leaving the page.',
              textAlign: compact ? TextAlign.center : TextAlign.left,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 40),
            const Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _FeaturePill(
                  icon: Icons.auto_awesome,
                  label: 'Explain in context',
                ),
                _FeaturePill(
                  icon: Icons.bookmark_outline,
                  label: 'Keep your place',
                ),
                _FeaturePill(icon: Icons.tune, label: 'Read your way'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SignInCard extends StatelessWidget {
  const _SignInCard({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 28 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.08),
              blurRadius: 36,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.waving_hand_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text('Welcome back', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              l10n.loginSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 30),
            FilledButton.icon(
              onPressed: onPressed,
              icon: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.login_rounded),
              label: Text(l10n.signInWithGoogle),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Private by design. Your library stays yours.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
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
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.auto_stories_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text('ReadMe.ai', style: theme.textTheme.titleLarge),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.34),
      ),
    ),
  );
}
