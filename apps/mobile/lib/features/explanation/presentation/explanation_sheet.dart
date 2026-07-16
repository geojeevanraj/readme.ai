import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/explanation_providers.dart';
import '../domain/explanation.dart';
import '../domain/prerequisite.dart';

/// Unified bottom sheet showing an explanation of any selection.
///
/// Shown over the reader (which stays visible). Handles loading, error + retry,
/// and close, and never navigates away. The content adapts automatically to the
/// backend's selection type; the user is not shown any mode.
class ExplanationSheet extends ConsumerWidget {
  const ExplanationSheet({required this.args, super.key});

  final ExplanationArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(explanationProvider(args));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _title(args.selectedText),
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: l10n.close,
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            switch (state) {
              AsyncData(:final value) => _ExplanationBody(explanation: value),
              AsyncError() => _ErrorBody(
                message: l10n.explanationError,
                onRetry: () => ref.invalidate(explanationProvider(args)),
              ),
              _ => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
            },
          ],
        ),
      ),
    );
  }

  String _title(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= 60) {
      return trimmed;
    }
    return '${trimmed.substring(0, 60)}…';
  }
}

class _ExplanationBody extends StatelessWidget {
  const _ExplanationBody({required this.explanation});

  final Explanation explanation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final meaning = explanation.meaning;
    final example = explanation.example;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (meaning != null && meaning.isNotEmpty) ...[
          Text(l10n.explanationMeaning, style: theme.textTheme.labelLarge),
          const SizedBox(height: 2),
          Text(meaning, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 12),
        ],
        Text(explanation.explanation, style: theme.textTheme.bodyLarge),
        if (example != null && example.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(l10n.explanationExample, style: theme.textTheme.labelLarge),
          const SizedBox(height: 2),
          Text(
            example,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (explanation.prerequisites.isNotEmpty) ...[
          const SizedBox(height: 12),
          _PrerequisitesSection(prerequisites: explanation.prerequisites),
        ],
      ],
    );
  }
}

class _PrerequisitesSection extends StatelessWidget {
  const _PrerequisitesSection({required this.prerequisites});

  final List<Prerequisite> prerequisites;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Theme(
      // Remove the divider lines for a cleaner look inside the sheet.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: Text(l10n.prerequisites),
        children: [
          for (final prerequisite in prerequisites)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.school_outlined),
              title: Text(prerequisite.name),
              subtitle: Text(prerequisite.reason),
            ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ),
        ],
      ),
    );
  }
}
