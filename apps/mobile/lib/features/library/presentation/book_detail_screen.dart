import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/formatters/byte_formatter.dart';
import '../application/library_controller.dart';
import '../application/library_providers.dart';
import '../domain/book.dart';

/// Shows a single book's metadata and offers deletion.
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
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref, bookState.value!),
            ),
        ],
      ),
      body: switch (bookState) {
        AsyncData(:final value) => _BookDetailView(book: value),
        AsyncError() => Center(child: Text(l10n.libraryLoadError)),
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
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

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

class _BookDetailView extends StatelessWidget {
  const _BookDetailView({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.menu_book_outlined,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(book.title, style: theme.textTheme.headlineSmall),
            ),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => context.goNamed(
            AppRoutes.readerName,
            pathParameters: {'bookId': book.id},
          ),
          icon: const Icon(Icons.chrome_reader_mode_outlined),
          label: Text(l10n.readBook),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 16),
        _DetailRow(label: l10n.fieldStatus, value: book.status.label),
        _DetailRow(label: l10n.fieldFileName, value: book.originalFilename),
        _DetailRow(
          label: l10n.fieldFileSize,
          value: formatBytes(book.fileSize),
        ),
        if (book.totalPages != null)
          _DetailRow(label: l10n.fieldPages, value: '${book.totalPages}'),
        _DetailRow(
          label: l10n.fieldUploadedAt,
          value: book.uploadedAt.toLocal().toString().split('.').first,
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
