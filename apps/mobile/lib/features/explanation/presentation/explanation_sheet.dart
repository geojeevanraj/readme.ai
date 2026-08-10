import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_semantics.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/explanation_providers.dart';
import '../domain/explanation.dart';
import '../domain/prerequisite.dart';
import '../domain/selection_type.dart';

/// The answer surface for a selected word, sentence or passage.
///
/// Deliberately a *partial* sheet: it is capped at just over half the screen so
/// the highlighted passage stays visible above it. An explanation that hides
/// the thing it explains forces the reader to memorise the question, and the
/// most common next action — "read that line again with this in mind" — becomes
/// a dismiss-and-reopen loop.
class ExplanationSheet extends ConsumerWidget {
  const ExplanationSheet({required this.args, this.onSave, super.key});

  final ExplanationArgs args;

  /// Saves the passage (and therefore the explanation's location) for later.
  final Future<void> Function()? onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(explanationProvider(args));

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.56,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.xs, Space.lg, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The question, quoted back. This is the anchor for everything
            // below it, so it is the first and largest thing in the sheet.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '“${_trimmed(args.selectedText)}”',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(width: Space.sm),
                IconButton(
                  tooltip: l10n.close,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
            const SizedBox(height: Space.md),
            Flexible(
              child: switch (state) {
                // Branch on capability rather than on the AsyncValue subclass:
                // a provider that is retrying reports `isLoading` while still
                // carrying its error, and an error must never render as an
                // indefinite spinner.
                AsyncValue(hasValue: true, :final value?) => _ExplanationBody(
                  explanation: value,
                  onSave: onSave,
                ),
                AsyncValue(hasError: true) => _ExplanationError(
                  onRetry: () => ref.invalidate(explanationProvider(args)),
                ),
                _ => const _ExplanationSkeleton(),
              },
            ),
          ],
        ),
      ),
    );
  }

  String _trimmed(String text) {
    final trimmed = text.trim();
    return trimmed.length <= 90 ? trimmed : '${trimmed.substring(0, 90)}…';
  }
}

class _ExplanationBody extends StatelessWidget {
  const _ExplanationBody({required this.explanation, required this.onSave});

  final Explanation explanation;
  final Future<void> Function()? onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantics = context.semantics;

    final meaning = explanation.meaning?.trim();
    final example = explanation.example?.trim();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A one-line definition, when the backend produced one, is what the
          // reader most often needs — so it leads, at reading size.
          if (meaning != null && meaning.isNotEmpty) ...[
            Text(meaning, style: theme.textTheme.headlineSmall),
            const SizedBox(height: Space.md),
          ],
          Text(
            explanation.explanation,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
          ),
          if (example != null && example.isNotEmpty) ...[
            const SizedBox(height: Space.base),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Space.md),
              decoration: BoxDecoration(
                color: semantics.surfaceSunken,
                borderRadius: Radii.all(Radii.md),
                border: Border(
                  left: BorderSide(color: semantics.amber, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.explanationExample.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: semantics.inkMuted,
                    ),
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    example,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: semantics.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (explanation.prerequisites.isNotEmpty) ...[
            const SizedBox(height: Space.base),
            _Prerequisites(prerequisites: explanation.prerequisites),
          ],
          const SizedBox(height: Space.base),
          Row(
            children: [
              _TypeBadge(type: explanation.selectionType),
              const Spacer(),
              if (onSave != null) _SaveButton(onSave: onSave!),
            ],
          ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom + Space.base),
        ],
      ),
    );
  }
}

/// Save resolves to a labelled bookmark, so an explanation the reader wants to
/// keep becomes a place they can return to.
class _SaveButton extends StatefulWidget {
  const _SaveButton({required this.onSave});

  final Future<void> Function() onSave;

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _saving = false;
  bool _saved = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave();
      if (mounted) setState(() => _saved = true);
    } on Object {
      // The caller surfaces failures; the button simply returns to its
      // actionable state so the reader can try again.
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_saved) {
      return Row(
        children: [
          Icon(Icons.check_rounded, size: 18, color: context.semantics.moss),
          const SizedBox(width: Space.xs),
          Text(
            l10n.explanationSaved,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: context.semantics.moss),
          ),
        ],
      );
    }

    return TextButton.icon(
      onPressed: _saving ? null : _save,
      icon: _saving
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.bookmark_add_outlined, size: 18),
      label: Text(l10n.explanationSave),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final SelectionType type;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final semantics = context.semantics;

    final label = switch (type) {
      SelectionType.word => l10n.explanationSelectionWord,
      SelectionType.sentence => l10n.explanationSelectionSentence,
      SelectionType.paragraph => l10n.explanationSelectionPassage,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.sm,
        vertical: Space.xs,
      ),
      decoration: BoxDecoration(
        color: semantics.accentTint,
        borderRadius: Radii.all(Radii.sm),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: semantics.accent),
      ),
    );
  }
}

class _Prerequisites extends StatelessWidget {
  const _Prerequisites({required this.prerequisites});

  final List<Prerequisite> prerequisites;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantics = context.semantics;

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: Radii.all(Radii.md),
          border: Border.all(color: semantics.hairline),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: Space.md),
          childrenPadding: const EdgeInsets.only(bottom: Space.sm),
          shape: const RoundedRectangleBorder(),
          collapsedShape: const RoundedRectangleBorder(),
          leading: Icon(
            Icons.account_tree_outlined,
            size: 20,
            color: semantics.inkFaint,
          ),
          title: Text(l10n.prerequisites, style: theme.textTheme.titleSmall),
          subtitle: Text(
            l10n.prerequisitesSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: semantics.inkMuted,
            ),
          ),
          children: [
            for (final prerequisite in prerequisites)
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Space.md,
                ),
                title: Text(
                  prerequisite.name,
                  style: theme.textTheme.titleSmall,
                ),
                subtitle: Text(prerequisite.reason),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shaped placeholder rather than a spinner: it tells the reader what is coming
/// (a short definition, then a paragraph) and keeps the sheet from resizing when
/// the answer lands.
class _ExplanationSkeleton extends StatelessWidget {
  const _ExplanationSkeleton();

  @override
  Widget build(BuildContext context) {
    final semantics = context.semantics;

    Widget bar(double widthFactor, double height) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: semantics.surfaceSunken,
          borderRadius: Radii.all(Radii.sm),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        bar(0.62, 22),
        const SizedBox(height: Space.base),
        bar(1, 12),
        const SizedBox(height: Space.sm),
        bar(0.94, 12),
        const SizedBox(height: Space.sm),
        bar(0.72, 12),
      ],
    );
  }
}

class _ExplanationError extends StatelessWidget {
  const _ExplanationError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantics = context.semantics;

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.explanationError, style: theme.textTheme.bodyLarge),
          const SizedBox(height: Space.xs),
          Text(
            l10n.connectionHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: semantics.inkMuted,
            ),
          ),
          const SizedBox(height: Space.base),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
