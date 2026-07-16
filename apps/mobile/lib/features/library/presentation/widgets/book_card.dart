import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/formatters/byte_formatter.dart';
import '../../domain/book.dart';
import '../../domain/book_status.dart';

/// Responsive editorial card for a book in the user's library.
class BookCard extends StatelessWidget {
  const BookCard({required this.book, required this.onTap, super.key});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxHeight < 250;
            return horizontal
                ? _HorizontalBook(book: book)
                : _VerticalBook(book: book);
          },
        ),
      ),
    );
  }
}

class _VerticalBook extends StatelessWidget {
  const _VerticalBook({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: SizedBox(
            width: double.infinity,
            child: _BookCover(book: book),
          ),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _StatusBadge(status: book.status)),
                    Icon(
                      Icons.arrow_outward_rounded,
                      size: 19,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  book.title,
                  style: theme.textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_fileKind(book)}  ·  ${formatBytes(book.fileSize)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HorizontalBook extends StatelessWidget {
  const _HorizontalBook({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(width: 124, child: _BookCover(book: book, compact: true)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatusBadge(status: book.status),
                const SizedBox(height: 14),
                Text(
                  book.title,
                  style: theme.textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_fileKind(book)}  ·  ${formatBytes(book.fileSize)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Icon(
            Icons.arrow_forward_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _BookCover extends StatelessWidget {
  const _BookCover({required this.book, this.compact = false});

  final Book book;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = _coverColors(book.title);
    return Hero(
      tag: 'book-cover-${book.id}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: compact ? -34 : -24,
              bottom: compact ? -28 : -34,
              child: Container(
                width: compact ? 96 : 150,
                height: compact ? 96 : 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              left: compact ? 14 : 22,
              top: compact ? 16 : 22,
              right: compact ? 12 : 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    color: Colors.white.withValues(alpha: 0.94),
                    size: compact ? 24 : 30,
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 30),
                    Text(
                      _initials(book.title),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontSize: 40,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              left: compact ? 14 : 22,
              bottom: compact ? 14 : 20,
              child: Text(
                'README.AI',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final BookStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (
      Color background,
      Color foreground,
      IconData icon,
    ) = switch (status) {
      BookStatus.ready => (
        AppColors.mint.withValues(alpha: 0.55),
        const Color(0xFF246145),
        Icons.check_circle_outline_rounded,
      ),
      BookStatus.failed => (
        theme.colorScheme.errorContainer,
        theme.colorScheme.onErrorContainer,
        Icons.error_outline_rounded,
      ),
      BookStatus.processing || BookStatus.uploading => (
        AppColors.apricot.withValues(alpha: 0.48),
        const Color(0xFF78440A),
        Icons.autorenew_rounded,
      ),
      BookStatus.uploaded => (
        theme.colorScheme.primaryContainer,
        theme.colorScheme.onPrimaryContainer,
        Icons.cloud_done_outlined,
      ),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 5),
            Text(
              status.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
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

List<Color> _coverColors(String title) {
  const palettes = [
    [Color(0xFF4D5FF7), Color(0xFF29369E)],
    [Color(0xFFDF7A45), Color(0xFF8F3D42)],
    [Color(0xFF237A68), Color(0xFF17483F)],
    [Color(0xFF7655C6), Color(0xFF41307D)],
    [Color(0xFF386C9B), Color(0xFF1D3C61)],
  ];
  return palettes[title.hashCode.abs() % palettes.length];
}
