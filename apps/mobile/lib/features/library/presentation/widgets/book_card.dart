import 'package:flutter/material.dart';

import '../../../../shared/formatters/byte_formatter.dart';
import '../../domain/book.dart';

/// A single book entry in the library list.
class BookCard extends StatelessWidget {
  const BookCard({required this.book, required this.onTap, super.key});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.menu_book_outlined,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          formatBytes(book.fileSize),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _StatusChip(label: book.status.label),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(label),
      labelStyle: theme.textTheme.labelSmall,
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      backgroundColor: theme.colorScheme.secondaryContainer,
    );
  }
}
