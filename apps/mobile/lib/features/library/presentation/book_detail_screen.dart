import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_semantics.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/formatters/byte_formatter.dart';
import '../../reader/application/reader_providers.dart';
import '../application/library_controller.dart';
import '../application/library_providers.dart';
import '../domain/book.dart';
import 'widgets/book_card.dart';

/// A single book, before entering the reader.
///
/// The action at the top is whatever the book's state actually allows: Read
/// when it is ready, a disabled explanation while it is being prepared, and
/// Try again when preparation failed. Offering "Read" on a book the backend has
/// not finished processing is the most common way this screen used to waste a
/// reader's time.
class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({required this.bookId, super.key});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final bookState = ref.watch(bookProvider(bookId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bookDetailTitle),
        actions: [
          if (bookState.hasValue)
            IconButton(
              tooltip: l10n.deleteBook,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _confirmDelete(context, ref, bookState.value!),
            ),
          const SizedBox(width: Space.xs),
        ],
      ),
      body: switch (bookState) {
        AsyncValue(hasValue: true, value: final book?) => _BookDetailView(
          book: book,
          onRead: () => context.goNamed(
            AppRoutes.readerName,
            pathParameters: {'bookId': book.id},
          ),
          onRetryProcessing: () => ref
              .read(libraryControllerProvider.notifier)
              .retryProcessing(book.id)
              .then((_) => ref.invalidate(bookProvider(bookId))),
        ),
        AsyncValue(hasError: true) => _DetailError(
          onRetry: () => ref.invalidate(bookProvider(bookId)),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Book book,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteBook),
        content: Text(l10n.deleteBookConfirmation(book.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await ref.read(libraryControllerProvider.notifier).deleteBook(book.id);
      router.goNamed(AppRoutes.homeName);
    } on Object {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.deleteFailed)));
    }
  }
}

class _BookDetailView extends ConsumerWidget {
  const _BookDetailView({
    required this.book,
    required this.onRead,
    required this.onRetryProcessing,
  });

  final Book book;
  final VoidCallback onRead;
  final VoidCallback onRetryProcessing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantics = context.semantics;

    final progress = book.status.isReadable
        ? ref.watch(readingProgressProvider(book.id)).value
        : null;
    final fraction = ((progress?.progressPercentage ?? 0) / 100).clamp(
      0.0,
      1.0,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.sm,
        Space.lg,
        Space.xxl,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 104,
              height: 148,
              child: BookCover(book: book, hero: true),
            ),
            const SizedBox(width: Space.base),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusBadge(status: book.status),
                  const SizedBox(height: Space.md),
                  Text(book.title, style: theme.textTheme.headlineSmall),
                  if (fraction > 0.001) ...[
                    const SizedBox(height: Space.md),
                    ClipRRect(
                      borderRadius: Radii.all(Radii.pill),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 4,
                        backgroundColor: semantics.surfaceSunken,
                      ),
                    ),
                    const SizedBox(height: Space.sm),
                    Text(
                      l10n.readerPercentRead((fraction * 100).round()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: semantics.inkMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.xl),

        // The primary action reflects the book's real state.
        if (book.status.isReadable)
          FilledButton.icon(
            onPressed: onRead,
            icon: const Icon(Icons.chrome_reader_mode_outlined, size: 18),
            label: Text(fraction > 0.001 ? l10n.libraryResume : l10n.readBook),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          )
        else if (book.status.hasFailed)
          FilledButton.icon(
            onPressed: onRetryProcessing,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l10n.bookRetryProcessing),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          )
        else
          FilledButton.icon(
            onPressed: null,
            icon: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            label: Text(l10n.bookNotReadyYet),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),

        if (book.status.hasFailed) ...[
          const SizedBox(height: Space.sm),
          Text(
            l10n.bookFailedHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: semantics.inkMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: Space.xl),
        Text(
          l10n.bookAboutFile.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: semantics.inkMuted,
          ),
        ),
        const SizedBox(height: Space.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: semantics.surface,
            borderRadius: Radii.all(Radii.lg),
            border: Border.all(color: semantics.hairline),
          ),
          child: Column(
            children: [
              _DetailRow(
                label: l10n.fieldFileName,
                value: book.originalFilename,
                mono: true,
              ),
              _DetailRow(
                label: l10n.fieldFileSize,
                value: formatBytes(book.fileSize),
                mono: true,
              ),
              if (book.totalPages != null)
                _DetailRow(label: l10n.fieldPages, value: '${book.totalPages}'),
              _DetailRow(
                label: l10n.fieldUploadedAt,
                value: _friendlyDate(book.uploadedAt.toLocal()),
                last: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.mono = false,
    this.last = false,
  });

  final String label;
  final String value;
  final bool mono;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.semantics;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.base,
            vertical: Space.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: semantics.inkMuted,
                  ),
                ),
              ),
              const SizedBox(width: Space.base),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: mono
                      ? AppTypography.mono(theme.textTheme.bodySmall)
                      : theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        if (!last) Divider(height: 1, color: semantics.hairline),
      ],
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantics = context.semantics;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 32, color: semantics.inkFaint),
            const SizedBox(height: Space.base),
            Text(l10n.libraryLoadError, style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.sm),
            Text(
              l10n.connectionHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: semantics.inkMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.xl),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

String _friendlyDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
