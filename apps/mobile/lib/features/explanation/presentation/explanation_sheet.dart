import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/explanation_providers.dart';
import '../domain/explanation.dart';
import '../domain/prerequisite.dart';
import '../domain/selection_type.dart';

/// Unified sheet showing the backend's contextual explanation for a selection.
class ExplanationSheet extends ConsumerWidget {
  const ExplanationSheet({required this.args, super.key});

  final ExplanationArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(explanationProvider(args));

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.84,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 2, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Explain this', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text(
                          '“${_title(args.selectedText)}”',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.close,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: switch (state) {
                  AsyncData(:final value) => SingleChildScrollView(
                    child: _ExplanationBody(explanation: value),
                  ),
                  AsyncError() => _ErrorBody(
                    message: l10n.explanationError,
                    onRetry: () => ref.invalidate(explanationProvider(args)),
                  ),
                  _ => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 38),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _title(String text) {
    final trimmed = text.trim();
    return trimmed.length <= 70 ? trimmed : '${trimmed.substring(0, 70)}…';
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
        _TypeBadge(type: explanation.selectionType),
        const SizedBox(height: 16),
        if (meaning != null && meaning.isNotEmpty) ...[
          _SectionLabel(
            icon: Icons.translate_rounded,
            label: l10n.explanationMeaning,
          ),
          const SizedBox(height: 8),
          Text(meaning, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 22),
        ],
        const _SectionLabel(
          icon: Icons.lightbulb_outline_rounded,
          label: 'In this context',
        ),
        const SizedBox(height: 8),
        Text(explanation.explanation, style: theme.textTheme.bodyLarge),
        if (example != null && example.isNotEmpty) ...[
          const SizedBox(height: 22),
          _SectionLabel(
            icon: Icons.format_quote_rounded,
            label: l10n.explanationExample,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              example,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
        if (explanation.prerequisites.isNotEmpty) ...[
          const SizedBox(height: 14),
          _PrerequisitesSection(prerequisites: explanation.prerequisites),
        ],
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final SelectionType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (type) {
      SelectionType.word => 'WORD',
      SelectionType.sentence => 'SENTENCE',
      SelectionType.paragraph => 'PASSAGE',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 17, color: theme.colorScheme.primary),
        const SizedBox(width: 7),
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
          ),
        ),
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
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(),
          collapsedShape: const RoundedRectangleBorder(),
          leading: const Icon(Icons.account_tree_outlined),
          title: Text(l10n.prerequisites),
          subtitle: const Text('Helpful ideas to know first'),
          children: [
            for (final prerequisite in prerequisites)
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: Icon(
                  Icons.school_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: Text(prerequisite.name),
                subtitle: Text(prerequisite.reason),
              ),
          ],
        ),
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 44,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
