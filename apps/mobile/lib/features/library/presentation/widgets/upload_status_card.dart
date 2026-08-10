import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_semantics.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/upload_controller.dart';

/// The file currently being uploaded, shown at the top of the library.
///
/// Two things this fixes: the reader can see that their file is going somewhere
/// (with real byte progress, not a spinner), and a failure keeps the file in
/// hand — Try again re-sends the bytes already chosen instead of sending the
/// reader back through the file picker.
class UploadStatusCard extends ConsumerWidget {
  const UploadStatusCard({required this.job, super.key});

  final UploadJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantics = context.semantics;
    final controller = ref.read(uploadControllerProvider.notifier);

    final failed = job.failed;
    final percent = (job.fraction * 100).round();

    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: failed ? semantics.rustTint : semantics.surface,
        borderRadius: Radii.all(Radii.lg),
        border: Border.all(color: failed ? semantics.rust : semantics.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                failed
                    ? Icons.error_outline_rounded
                    : Icons.upload_file_rounded,
                size: 20,
                color: failed ? semantics.rustInk : semantics.accent,
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      failed
                          ? l10n.uploadFailedTitle
                          : job.isComplete
                          ? l10n.uploadPreparing
                          : l10n.uploadingPercent(percent),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: failed ? semantics.rustInk : semantics.ink,
                      ),
                    ),
                    const SizedBox(height: Space.xxs),
                    Text(
                      job.filename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.mono(theme.textTheme.bodySmall)
                          .copyWith(
                            color: failed
                                ? semantics.rustInk
                                : semantics.inkMuted,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!failed) ...[
            const SizedBox(height: Space.md),
            ClipRRect(
              borderRadius: Radii.all(Radii.pill),
              child: LinearProgressIndicator(
                // Indeterminate once the bytes are gone and the server is
                // creating the book: pretending to know that duration would be
                // a lie.
                value: job.isComplete ? null : job.fraction,
                minHeight: 4,
                backgroundColor: semantics.surfaceSunken,
              ),
            ),
          ] else ...[
            const SizedBox(height: Space.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.connectionHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: semantics.rustInk,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: controller.dismiss,
                  child: Text(l10n.uploadDismiss),
                ),
                const SizedBox(width: Space.xs),
                FilledButton(
                  onPressed: controller.retry,
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
