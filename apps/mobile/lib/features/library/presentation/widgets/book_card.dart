import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_semantics.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/formatters/byte_formatter.dart';
import '../../domain/book.dart';
import '../../domain/book_status.dart';

/// A book in the library, as a row.
///
/// Rows rather than a grid of covers: these covers are generated placeholders,
/// not real artwork, so they carry no recognition value at grid size. A row
/// gives the title room to be read and leaves space for the state a reader
/// actually needs — whether the book is ready, and what to do if it is not.
class BookCard extends StatelessWidget {
  const BookCard({
    required this.book,
    required this.onTap,
    this.onRetryProcessing,
    super.key,
  });

  final Book book;
  final VoidCallback onTap;

  /// Invoked when a failed book's "Try again" is tapped.
  final VoidCallback? onRetryProcessing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantics = context.semantics;

    return Semantics(
      button: true,
      label: '${book.title}, ${book.status.label}',
      child: ExcludeSemantics(
        child: Material(
          color: semantics.surface,
          shape: RoundedRectangleBorder(
            borderRadius: Radii.all(Radii.lg),
            side: BorderSide(color: semantics.hairline),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 66,
                        child: BookCover(book: book, compact: true, hero: true),
                      ),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: Space.xs),
                            Text(
                              '${_fileKind(book)} · ${formatBytes(book.fileSize)}',
                              style: AppTypography.mono(
                                theme.textTheme.bodySmall,
                              ).copyWith(color: semantics.inkFaint),
                            ),
                            const SizedBox(height: Space.sm),
                            StatusBadge(status: book.status),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: semantics.inkFaint,
                      ),
                    ],
                  ),

                  // While the backend is preparing the book there is nothing
                  // to tap, so the row says so rather than looking broken.
                  // Deliberately static text rather than an indeterminate bar:
                  // the status is refreshed by polling every few seconds, and a
                  // bar that animates forever on a list row is noise (and never
                  // lets the frame scheduler go idle).
                  if (book.status.isTransient) ...[
                    const SizedBox(height: Space.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.bookPreparingHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: semantics.inkMuted,
                        ),
                      ),
                    ),
                  ],

                  // A failed book is recoverable: the file is already uploaded,
                  // so processing can simply be re-run.
                  if (book.status.hasFailed && onRetryProcessing != null) ...[
                    const SizedBox(height: Space.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.bookFailedHint,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: semantics.inkMuted,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: onRetryProcessing,
                          child: Text(l10n.bookRetryProcessing),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Generated cover for a book.
///
/// Marked as decorative for assistive technology: the initials and wordmark are
/// derived from the title, so reading them aloud after the title would just be
/// noise.
///
/// Pass [hero] to animate the cover between screens. Only one cover for a given
/// book may opt in per screen — two Heroes with the same tag in one subtree is a
/// framework assertion, which is exactly what happens when the same book appears
/// both in the resume card and in the list below it.
class BookCover extends StatelessWidget {
  const BookCover({
    required this.book,
    this.compact = false,
    this.hero = false,
    super.key,
  });

  final Book book;
  final bool compact;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.coverFor(book.title);

    final cover = ClipRRect(
      borderRadius: Radii.all(compact ? Radii.sm : Radii.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        // A Stack (clipped by the ClipRRect above) rather than a Column: the
        // cover has a fixed aspect box, and text that grows with the platform
        // font-size setting must be allowed to run past the edge instead of
        // throwing a layout overflow.
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: compact ? Space.sm : Space.base,
              right: compact ? Space.sm : Space.base,
              bottom: compact ? Space.sm : Space.base,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _initials(book.title),
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: AppTypography.serifFamily,
                      fontFamilyFallback: AppTypography.serifFallback,
                      fontSize: compact ? 20 : 44,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: Space.sm),
                    Text(
                      'README.AI',
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        letterSpacing: 1.6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return ExcludeSemantics(
      child: hero ? Hero(tag: 'book-cover-${book.id}', child: cover) : cover,
    );
  }
}

/// Coloured pill describing where a book is in its lifecycle.
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.status, super.key});

  final BookStatus status;

  @override
  Widget build(BuildContext context) {
    final semantics = context.semantics;

    final (
      Color background,
      Color foreground,
      IconData icon,
    ) = switch (status) {
      BookStatus.ready => (
        semantics.mossTint,
        semantics.mossInk,
        Icons.check_circle_outline_rounded,
      ),
      BookStatus.failed => (
        semantics.rustTint,
        semantics.rustInk,
        Icons.error_outline_rounded,
      ),
      BookStatus.uploading || BookStatus.uploaded || BookStatus.processing => (
        semantics.amberTint,
        semantics.amberInk,
        Icons.hourglass_top_rounded,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.sm,
        vertical: Space.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: Radii.all(Radii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: Space.xs),
          Text(
            status.label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

String _fileKind(Book book) {
  final dot = book.originalFilename.lastIndexOf('.');
  if (dot == -1) return 'DOCUMENT';
  return book.originalFilename.substring(dot + 1).toUpperCase();
}

String _initials(String title) {
  final words = title
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2);
  final result = words.map((word) => word[0].toUpperCase()).join();
  return result.isEmpty ? 'R' : result;
}
